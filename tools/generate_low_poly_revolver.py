"""Generate the signature RevolverArena revolver, glTF, and QA renders.

The model uses +Y up and -Z forward. Grip center is the shared weapon origin;
Cylinder and Hammer instead have translated nodes with local animation pivots.
All rotation and scale are baked into vertex positions before export.
"""

from __future__ import annotations

import base64
import json
import math
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "assets" / "revolver"
GAMEPLAY_SCALE = 0.8


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def mul(a, scalar):
    return (a[0] * scalar, a[1] * scalar, a[2] * scalar)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def cross(a, b):
    return (
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    )


def length(vector):
    return math.sqrt(dot(vector, vector))


def normalize(vector):
    magnitude = length(vector)
    if magnitude <= 1e-10:
        return (0.0, 0.0, 0.0)
    return mul(vector, 1.0 / magnitude)


def merge_meshes(meshes):
    vertices = []
    faces = []
    for component_vertices, component_faces in meshes:
        offset = len(vertices)
        vertices.extend(component_vertices)
        faces.extend(tuple(index + offset for index in face) for face in component_faces)
    return vertices, faces


def box(center, size):
    cx, cy, cz = center
    hx, hy, hz = (size[0] * 0.5, size[1] * 0.5, size[2] * 0.5)
    vertices = [
        (cx - hx, cy - hy, cz - hz),
        (cx + hx, cy - hy, cz - hz),
        (cx + hx, cy + hy, cz - hz),
        (cx - hx, cy + hy, cz - hz),
        (cx - hx, cy - hy, cz + hz),
        (cx + hx, cy - hy, cz + hz),
        (cx + hx, cy + hy, cz + hz),
        (cx - hx, cy + hy, cz + hz),
    ]
    faces = [
        (0, 2, 1), (0, 3, 2),
        (4, 5, 6), (4, 6, 7),
        (0, 1, 5), (0, 5, 4),
        (3, 7, 6), (3, 6, 2),
        (0, 4, 7), (0, 7, 3),
        (1, 2, 6), (1, 6, 5),
    ]
    return vertices, faces


def extrude_yz(points, half_width):
    """Extrude a convex CCW polygon in the YZ plane along X."""
    count = len(points)
    vertices = [(-half_width, y, z) for y, z in points]
    vertices.extend((half_width, y, z) for y, z in points)
    faces = []

    for index in range(count):
        next_index = (index + 1) % count
        back_a = index
        back_b = next_index
        front_a = count + index
        front_b = count + next_index
        faces.extend(((back_a, back_b, front_b), (back_a, front_b, front_a)))

    for index in range(1, count - 1):
        faces.append((0, index + 1, index))
        faces.append((count, count + index, count + index + 1))

    return vertices, faces


def cylinder_z(center, radius_x, radius_y, depth, segments):
    cx, cy, cz = center
    half_depth = depth * 0.5
    vertices = []
    for z in (cz - half_depth, cz + half_depth):
        for index in range(segments):
            angle = math.tau * index / segments
            vertices.append((cx + radius_x * math.cos(angle), cy + radius_y * math.sin(angle), z))

    back_center = len(vertices)
    vertices.append((cx, cy, cz - half_depth))
    front_center = len(vertices)
    vertices.append((cx, cy, cz + half_depth))
    faces = []

    for index in range(segments):
        next_index = (index + 1) % segments
        back_a = index
        back_b = next_index
        front_a = segments + index
        front_b = segments + next_index
        faces.extend(((back_a, back_b, front_b), (back_a, front_b, front_a)))
        faces.append((back_center, back_b, back_a))
        faces.append((front_center, front_a, front_b))

    return vertices, faces


def cylinder_x(center, radius_y, radius_z, width, segments):
    cx, cy, cz = center
    half_width = width * 0.5
    vertices = []
    for x in (cx - half_width, cx + half_width):
        for index in range(segments):
            angle = math.tau * index / segments
            vertices.append((x, cy + radius_y * math.cos(angle), cz + radius_z * math.sin(angle)))

    left_center = len(vertices)
    vertices.append((cx - half_width, cy, cz))
    right_center = len(vertices)
    vertices.append((cx + half_width, cy, cz))
    faces = []

    for index in range(segments):
        next_index = (index + 1) % segments
        left_a = index
        left_b = next_index
        right_a = segments + index
        right_b = segments + next_index
        faces.extend(((left_a, left_b, right_b), (left_a, right_b, right_a)))
        faces.append((left_center, left_b, left_a))
        faces.append((right_center, right_a, right_b))

    return vertices, faces


def build_model():
    def primitive(material, geometry):
        return {"material": material, "geometry": geometry}

    grip = extrude_yz(
        [(0.66, -0.10), (0.66, 0.42), (-0.87, 0.67), (-0.91, 0.14)],
        0.37,
    )
    grip_cap = box((0.0, -0.92, 0.40), (0.82, 0.13, 0.65))

    # The frame bridges above and below the cylinder instead of hiding it.
    frame = merge_meshes(
        [
            box((0.0, 1.10, 0.27), (1.18, 0.95, 0.58)),
            box((0.0, 1.81, -0.53), (0.96, 0.22, 1.37)),
            box((0.0, 0.48, -0.57), (0.76, 0.19, 1.19)),
            box((0.0, 0.69, 0.05), (0.82, 0.38, 0.63)),
            box((0.0, 0.11, -0.18), (0.58, 0.54, 0.15)),
            box((0.0, 0.11, -1.01), (0.58, 0.54, 0.15)),
            box((0.0, -0.17, -0.60), (0.58, 0.13, 0.97)),
        ]
    )

    barrel = merge_meshes(
        [
            cylinder_z((0.0, 1.16, -2.05), 0.41, 0.39, 1.75, 10),
            cylinder_z((0.0, 1.16, -2.91), 0.47, 0.43, 0.17, 10),
            box((0.0, 1.56, -2.03), (0.52, 0.14, 1.72)),
            box((0.0, 0.76, -2.00), (0.60, 0.18, 1.60)),
        ]
    )

    cylinder_pivot = (0.0, 1.13, -0.64)
    cylinder_body = merge_meshes(
        [
            cylinder_x((0.0, 0.0, 0.0), 0.65, 0.65, 1.35, 10),
            cylinder_x((-0.66, 0.0, 0.0), 0.69, 0.69, 0.12, 10),
            cylinder_x((0.66, 0.0, 0.0), 0.69, 0.69, 0.12, 10),
        ]
    )
    chamber_marks = []
    for side in (-1, 1):
        chamber_marks.append(cylinder_x((side * 0.75, 0.0, 0.0), 0.17, 0.17, 0.035, 8))
        for index in range(6):
            angle = math.tau * index / 6
            chamber_marks.append(
                cylinder_x(
                    (side * 0.75, 0.43 * math.cos(angle), 0.43 * math.sin(angle)),
                    0.105, 0.105, 0.035, 8,
                )
            )

    hammer_pivot = (0.0, 1.49, 0.30)
    hammer = merge_meshes(
        [
            extrude_yz(
                [(-0.03, -0.16), (0.35, -0.11), (0.69, 0.49), (0.43, 0.66)],
                0.27,
            ),
            cylinder_x((0.0, 0.0, 0.0), 0.16, 0.16, 0.59, 8),
        ]
    )

    trigger = extrude_yz(
        [(0.31, -0.54), (0.31, -0.37), (-0.07, -0.42), (-0.11, -0.55)],
        0.11,
    )

    front_sight = extrude_yz(
        [(1.52, -2.81), (1.81, -2.78), (1.89, -2.69), (1.52, -2.62)],
        0.13,
    )

    objects = [
        {"name": "Handle", "pivot": (0, 0, 0), "primitives": [
            primitive("WoodGrip", grip), primitive("DarkMetal", grip_cap)]},
        {"name": "Frame", "pivot": (0, 0, 0), "primitives": [primitive("DarkMetal", frame)]},
        {"name": "Barrel", "pivot": (0, 0, 0), "primitives": [primitive("DarkMetal", barrel)]},
        {"name": "Cylinder", "pivot": cylinder_pivot, "animation_axis": "+X", "primitives": [
            primitive("CylinderMetal", cylinder_body),
            primitive("DarkMetal", merge_meshes(chamber_marks))]},
        {"name": "Hammer", "pivot": hammer_pivot, "animation_axis": "+X", "primitives": [
            primitive("DarkMetal", hammer)]},
        {"name": "Trigger", "pivot": (0, 0, 0), "primitives": [primitive("DarkMetal", trigger)]},
        {"name": "FrontSight", "pivot": (0, 0, 0), "primitives": [
            primitive("CylinderMetal", front_sight)]},
    ]
    for item in objects:
        item["pivot"] = mul(item["pivot"], GAMEPLAY_SCALE)
        for mesh in item["primitives"]:
            vertices, faces = mesh["geometry"]
            mesh["geometry"] = ([mul(vertex, GAMEPLAY_SCALE) for vertex in vertices], faces)
    return objects


MATERIALS = {
    "DarkMetal": {
        "baseColorFactor": [0.11, 0.14, 0.16, 1.0],
        "metallicFactor": 0.72,
        "roughnessFactor": 0.41,
        "preview": (76, 93, 105),
    },
    "CylinderMetal": {
        "baseColorFactor": [0.25, 0.30, 0.33, 1.0],
        "metallicFactor": 0.72,
        "roughnessFactor": 0.35,
        "preview": (146, 164, 174),
    },
    "WoodGrip": {
        "baseColorFactor": [0.37, 0.16, 0.08, 1.0],
        "metallicFactor": 0.0,
        "roughnessFactor": 0.66,
        "preview": (153, 82, 46),
    },
}


def validate_model(objects):
    expected_names = ["Handle", "Frame", "Barrel", "Cylinder", "Hammer", "Trigger", "FrontSight"]
    actual_names = [item["name"] for item in objects]
    if actual_names != expected_names:
        raise ValueError(f"Object names do not match requirement: {actual_names}")

    report_objects = []
    all_vertices = []
    for item in objects:
        world_vertices = []
        triangle_count = 0
        vertex_count = 0
        for primitive in item["primitives"]:
            vertices, faces = primitive["geometry"]
            vertex_count += len(vertices)
            triangle_count += len(faces)
            world_vertices.extend(add(vertex, item["pivot"]) for vertex in vertices)
            edge_counts = {}
            for face in faces:
                a, b, c = (vertices[index] for index in face)
                if length(cross(sub(b, a), sub(c, a))) <= 1e-8:
                    raise ValueError(f"Degenerate triangle in {item['name']}")
                for first, second in ((face[0], face[1]), (face[1], face[2]), (face[2], face[0])):
                    edge = tuple(sorted((first, second)))
                    edge_counts[edge] = edge_counts.get(edge, 0) + 1
            if any(count != 2 for count in edge_counts.values()):
                raise ValueError(f"Non-manifold edge in {item['name']}")

        all_vertices.extend(world_vertices)
        minimum = [min(vertex[axis] for vertex in world_vertices) for axis in range(3)]
        maximum = [max(vertex[axis] for vertex in world_vertices) for axis in range(3)]
        report_objects.append(
            {
                "name": item["name"],
                "materials": [primitive["material"] for primitive in item["primitives"]],
                "pivot": item["pivot"],
                "animation_axis": item.get("animation_axis"),
                "vertices": vertex_count,
                "triangles": triangle_count,
                "closed_manifold": True,
                "bounds_min": [round(value, 4) for value in minimum],
                "bounds_max": [round(value, 4) for value in maximum],
            }
        )

    minimum = [min(vertex[axis] for vertex in all_vertices) for axis in range(3)]
    maximum = [max(vertex[axis] for vertex in all_vertices) for axis in range(3)]
    return {
        "format": "glTF 2.0",
        "units": "Roblox studs",
        "gameplay_scale": GAMEPLAY_SCALE,
        "up_axis": "+Y",
        "forward_axis": "-Z",
        "weapon_origin": "Grip center",
        "transforms_applied": "Rotation and scale baked; Cylinder/Hammer node translations are animation pivots",
        "object_count": len(objects),
        "triangle_count": sum(
            len(primitive["geometry"][1])
            for item in objects for primitive in item["primitives"]
        ),
        "bounds_min": [round(value, 4) for value in minimum],
        "bounds_max": [round(value, 4) for value in maximum],
        "objects": report_objects,
    }


def export_gltf(objects, output_path):
    material_names = list(MATERIALS)
    gltf = {
        "asset": {
            "version": "2.0",
            "generator": "RevolverArena deterministic low-poly generator",
            "extras": {
                "upAxis": "+Y",
                "forwardAxis": "-Z",
                "weaponOrigin": "Grip center",
                "transformsApplied": "Rotation and scale baked into geometry",
            },
        },
        "scene": 0,
        "scenes": [{"name": "Revolver", "nodes": []}],
        "nodes": [],
        "meshes": [],
        "materials": [],
        "accessors": [],
        "bufferViews": [],
        "buffers": [],
    }

    for name in material_names:
        material = MATERIALS[name]
        gltf["materials"].append(
            {
                "name": name,
                "pbrMetallicRoughness": {
                    "baseColorFactor": material["baseColorFactor"],
                    "metallicFactor": material["metallicFactor"],
                    "roughnessFactor": material["roughnessFactor"],
                },
                "doubleSided": False,
            }
        )

    blob = bytearray()

    def append_buffer_view(data, target):
        while len(blob) % 4:
            blob.append(0)
        offset = len(blob)
        blob.extend(data)
        index = len(gltf["bufferViews"])
        gltf["bufferViews"].append(
            {"buffer": 0, "byteOffset": offset, "byteLength": len(data), "target": target}
        )
        return index

    for item in objects:
        mesh_primitives = []
        for primitive in item["primitives"]:
            source_vertices, source_faces = primitive["geometry"]
            positions = []
            normals = []
            indices = []

            for face in source_faces:
                a, b, c = (source_vertices[index] for index in face)
                normal = normalize(cross(sub(b, a), sub(c, a)))
                for vertex in (a, b, c):
                    indices.append(len(positions))
                    positions.append(vertex)
                    normals.append(normal)

            position_view = append_buffer_view(
                b"".join(struct.pack("<fff", *value) for value in positions), 34962
            )
            normal_view = append_buffer_view(
                b"".join(struct.pack("<fff", *value) for value in normals), 34962
            )
            index_view = append_buffer_view(
                b"".join(struct.pack("<H", value) for value in indices), 34963
            )

            position_accessor = len(gltf["accessors"])
            gltf["accessors"].append(
                {
                    "bufferView": position_view,
                    "componentType": 5126,
                    "count": len(positions),
                    "type": "VEC3",
                    "min": [min(value[axis] for value in positions) for axis in range(3)],
                    "max": [max(value[axis] for value in positions) for axis in range(3)],
                }
            )
            normal_accessor = len(gltf["accessors"])
            gltf["accessors"].append(
                {"bufferView": normal_view, "componentType": 5126,
                 "count": len(normals), "type": "VEC3"}
            )
            index_accessor = len(gltf["accessors"])
            gltf["accessors"].append(
                {"bufferView": index_view, "componentType": 5123,
                 "count": len(indices), "type": "SCALAR", "min": [0], "max": [max(indices)]}
            )
            mesh_primitives.append(
                {
                    "attributes": {"POSITION": position_accessor, "NORMAL": normal_accessor},
                    "indices": index_accessor,
                    "material": material_names.index(primitive["material"]),
                    "mode": 4,
                }
            )

        mesh_index = len(gltf["meshes"])
        gltf["meshes"].append({"name": item["name"], "primitives": mesh_primitives})
        node_index = len(gltf["nodes"])
        node = {"name": item["name"], "mesh": mesh_index,
                "extras": {"animationAxis": item.get("animation_axis")}}
        if item["pivot"] != (0, 0, 0):
            node["translation"] = item["pivot"]
        gltf["nodes"].append(node)
        gltf["scenes"][0]["nodes"].append(node_index)

    gltf["buffers"].append(
        {
            "byteLength": len(blob),
            "uri": "data:application/octet-stream;base64," + base64.b64encode(blob).decode("ascii"),
        }
    )
    output_path.write_text(json.dumps(gltf, indent=2), encoding="utf-8")


def png_chunk(chunk_type, data):
    return (
        struct.pack(">I", len(data))
        + chunk_type
        + data
        + struct.pack(">I", zlib.crc32(chunk_type + data) & 0xFFFFFFFF)
    )


def write_png(path, width, height, pixels):
    raw = bytearray()
    stride = width * 3
    for row in range(height):
        raw.append(0)
        start = row * stride
        raw.extend(pixels[start : start + stride])
    payload = bytearray(b"\x89PNG\r\n\x1a\n")
    payload.extend(png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)))
    payload.extend(png_chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
    payload.extend(png_chunk(b"IEND", b""))
    path.write_bytes(payload)


def render(objects, width, height, eye, target, orthographic_height=None, fov_degrees=34):
    background = (177, 184, 196)
    pixels = bytearray(background * (width * height))
    z_buffer = [float("inf")] * (width * height)

    forward = normalize(sub(target, eye))
    right = normalize(cross(forward, (0.0, 1.0, 0.0)))
    camera_up = normalize(cross(right, forward))
    light_direction = normalize((-0.45, 0.8, -0.55))
    perspective_scale = (height * 0.5) / math.tan(math.radians(fov_degrees) * 0.5)
    orthographic_scale = height / orthographic_height if orthographic_height else 1.0

    def project(vertex):
        relative = sub(vertex, eye)
        camera_x = dot(relative, right)
        camera_y = dot(relative, camera_up)
        camera_z = dot(relative, forward)
        if camera_z <= 0.01:
            return None
        if orthographic_height:
            return (
                width * 0.5 + camera_x * orthographic_scale,
                height * 0.5 - camera_y * orthographic_scale,
                camera_z,
            )
        return (
            width * 0.5 + camera_x * perspective_scale / camera_z,
            height * 0.5 - camera_y * perspective_scale / camera_z,
            camera_z,
        )

    for item in objects:
        for primitive in item["primitives"]:
            vertices, faces = primitive["geometry"]
            base_color = MATERIALS[primitive["material"]]["preview"]
            for face in faces:
                world_points = [add(vertices[index], item["pivot"]) for index in face]
                projected = [project(vertex) for vertex in world_points]
                if any(point is None for point in projected):
                    continue

                a, b, c = world_points
                normal = normalize(cross(sub(b, a), sub(c, a)))
                diffuse = max(0.0, dot(normal, light_direction))
                rim = 0.12 * abs(dot(normal, normalize(sub(eye, a))))
                brightness = min(1.2, 0.42 + 0.58 * diffuse + rim)
                color = tuple(max(0, min(255, int(channel * brightness))) for channel in base_color)

                p0, p1, p2 = projected
                min_x = max(0, int(math.floor(min(p0[0], p1[0], p2[0]))))
                max_x = min(width - 1, int(math.ceil(max(p0[0], p1[0], p2[0]))))
                min_y = max(0, int(math.floor(min(p0[1], p1[1], p2[1]))))
                max_y = min(height - 1, int(math.ceil(max(p0[1], p1[1], p2[1]))))
                denominator = (p1[1] - p2[1]) * (p0[0] - p2[0]) + (p2[0] - p1[0]) * (p0[1] - p2[1])
                if abs(denominator) <= 1e-8:
                    continue

                for pixel_y in range(min_y, max_y + 1):
                    sample_y = pixel_y + 0.5
                    for pixel_x in range(min_x, max_x + 1):
                        sample_x = pixel_x + 0.5
                        alpha = (
                            (p1[1] - p2[1]) * (sample_x - p2[0])
                            + (p2[0] - p1[0]) * (sample_y - p2[1])
                        ) / denominator
                        beta = (
                            (p2[1] - p0[1]) * (sample_x - p2[0])
                            + (p0[0] - p2[0]) * (sample_y - p2[1])
                        ) / denominator
                        gamma = 1.0 - alpha - beta
                        if alpha < -1e-6 or beta < -1e-6 or gamma < -1e-6:
                            continue

                        depth = alpha * p0[2] + beta * p1[2] + gamma * p2[2]
                        buffer_index = pixel_y * width + pixel_x
                        if depth >= z_buffer[buffer_index]:
                            continue
                        z_buffer[buffer_index] = depth
                        color_index = buffer_index * 3
                        pixels[color_index : color_index + 3] = bytes(color)

    return pixels


def combine_previews(images, panel_width, panel_height, gap=18):
    total_width = panel_width * len(images) + gap * (len(images) - 1)
    pixels = bytearray((138, 145, 157) * (total_width * panel_height))
    for image_index, image in enumerate(images):
        x_offset = image_index * (panel_width + gap)
        for row in range(panel_height):
            source_start = row * panel_width * 3
            target_start = (row * total_width + x_offset) * 3
            pixels[target_start : target_start + panel_width * 3] = image[
                source_start : source_start + panel_width * 3
            ]
    return total_width, panel_height, pixels


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    objects = build_model()
    report = validate_model(objects)
    export_gltf(objects, OUTPUT_DIR / "stylized_low_poly_revolver.gltf")
    (OUTPUT_DIR / "stylized_low_poly_revolver_manifest.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8"
    )

    width, height = 720, 480
    first_person = render(
        objects, width, height,
        eye=(4.0, 2.50, 1.80),
        target=(0.0, 0.92, -1.45),
        fov_degrees=48,
    )
    side = render(
        objects,
        width,
        height,
        eye=(6.0, 0.72, -1.05),
        target=(0.0, 0.72, -1.05),
        orthographic_height=3.85,
    )
    front = render(
        objects,
        width,
        height,
        eye=(0.0, 1.18, -7.0),
        target=(0.0, 1.18, -1.1),
        orthographic_height=3.35,
    )
    perspective = render(
        objects,
        width,
        height,
        eye=(5.2, 3.1, -5.3),
        target=(0.0, 0.84, -1.05),
        fov_degrees=32,
    )

    write_png(OUTPUT_DIR / "revolver_first_person.png", width, height, first_person)
    write_png(OUTPUT_DIR / "revolver_side.png", width, height, side)
    write_png(OUTPUT_DIR / "revolver_front.png", width, height, front)
    write_png(OUTPUT_DIR / "revolver_perspective.png", width, height, perspective)
    review_width, review_height, review = combine_previews(
        [first_person, side, perspective, front], width, height
    )
    write_png(OUTPUT_DIR / "revolver_review.png", review_width, review_height, review)

    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
