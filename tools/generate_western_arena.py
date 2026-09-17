"""Generate the Rojo-managed Western Arena V1 JSON model."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "src" / "workspace" / "Arena.model.json"

DUST = [0.58, 0.40, 0.22]
DUST_LIGHT = [0.69, 0.50, 0.29]
SANDSTONE = [0.43, 0.27, 0.16]
WOOD = [0.31, 0.17, 0.08]
WOOD_LIGHT = [0.47, 0.29, 0.13]
WOOD_DARK = [0.17, 0.09, 0.045]
SALOON_RED = [0.37, 0.14, 0.09]
STORE_OCHRE = [0.48, 0.29, 0.10]
SHERIFF_GRAY = [0.34, 0.34, 0.30]
STABLE_BROWN = [0.28, 0.14, 0.065]
WINDOW_DARK = [0.08, 0.10, 0.12]
METAL_DARK = [0.12, 0.13, 0.14]
CACTUS_GREEN = [0.20, 0.34, 0.18]
LANTERN_GLOW = [1.0, 0.55, 0.16]
LOBBY_BLUE = [0.16, 0.29, 0.34]


def part(name, position, size, color, material="WoodPlanks", children=None, **properties):
    instance_properties = {
        "Anchored": True,
        "Color": color,
        "Material": material,
        "Position": position,
        "Size": size,
    }
    instance_properties.update(properties)
    instance = {"Name": name, "ClassName": "Part", "Properties": instance_properties}
    if children:
        instance["Children"] = children
    return instance


def point_light(color=LANTERN_GLOW, brightness=1.6, light_range=12):
    return {
        "Name": "WarmLight",
        "ClassName": "PointLight",
        "Properties": {
            "Brightness": brightness,
            "Color": color,
            "Range": light_range,
            "Shadows": False,
        },
    }


def lantern(name, position, height=7):
    x, y, z = position
    return model(
        name,
        [
            part("Post", [x, y + height / 2, z], [0.45, height, 0.45], WOOD_DARK, "Wood"),
            part("Arm", [x, y + height - 0.4, z - 0.65], [0.4, 0.4, 1.6], WOOD_DARK, "Wood"),
            part(
                "Glow",
                [x, y + height - 1.0, z - 1.15],
                [0.55, 0.75, 0.55],
                LANTERN_GLOW,
                "Neon",
                children=[point_light()],
                CanCollide=False,
                CanQuery=False,
                CanTouch=False,
                Shape="Ball",
            ),
        ],
    )


def wagon(name, position):
    x, y, z = position
    return model(
        name,
        [
            part("Bed", [x, y + 2.2, z], [8, 2.2, 4], WOOD, "WoodPlanks"),
            part("SideNorth", [x, y + 3.7, z - 1.8], [8, 1.6, 0.35], WOOD_LIGHT, "Wood"),
            part("SideSouth", [x, y + 3.7, z + 1.8], [8, 1.6, 0.35], WOOD_LIGHT, "Wood"),
            part("WheelWest", [x - 3.2, y + 1.7, z - 2.15], [0.7, 3.4, 3.4], WOOD_DARK, "Wood", Shape="Cylinder"),
            part("WheelEast", [x + 3.2, y + 1.7, z - 2.15], [0.7, 3.4, 3.4], WOOD_DARK, "Wood", Shape="Cylinder"),
            part("WheelWestRear", [x - 3.2, y + 1.7, z + 2.15], [0.7, 3.4, 3.4], WOOD_DARK, "Wood", Shape="Cylinder"),
            part("WheelEastRear", [x + 3.2, y + 1.7, z + 2.15], [0.7, 3.4, 3.4], WOOD_DARK, "Wood", Shape="Cylinder"),
        ],
    )


def cactus(name, position, height=6):
    x, y, z = position
    return model(
        name,
        [
            part("Trunk", [x, y + height / 2, z], [height, 1.1, 1.1], CACTUS_GREEN, "SmoothPlastic", Orientation=[0, 0, 90], Shape="Cylinder"),
            part("ArmA", [x + 1.1, y + height * 0.55, z], [2.2, 0.65, 0.65], CACTUS_GREEN, "SmoothPlastic", Shape="Cylinder"),
            part("ArmB", [x - 0.9, y + height * 0.72, z], [1.8, 0.6, 0.6], CACTUS_GREEN, "SmoothPlastic", Shape="Cylinder"),
        ],
    )


def barrel(name, position):
    return part(
        name,
        position,
        [3.6, 3.0, 3.0],
        WOOD_DARK,
        "Wood",
        Orientation=[0, 0, 90],
        Shape="Cylinder",
    )


def lobby_spawn(name, position):
    return {
        "Name": name,
        "ClassName": "SpawnLocation",
        "Properties": {
            "AllowTeamChangeOnTouch": False,
            "Anchored": True,
            "CanCollide": False,
            "CanQuery": False,
            "Color": DUST_LIGHT,
            "Duration": 0,
            "Enabled": True,
            "Material": "Sand",
            "Neutral": True,
            "Position": position,
            "Size": [7, 1, 7],
            "Transparency": 1,
        },
    }


def combat_marker(name, position):
    return part(
        name, position, [7, 0.2, 7], DUST_LIGHT, "SmoothPlastic",
        CanCollide=False, CanQuery=False, CanTouch=False, Transparency=1,
    )


def model(name, children):
    return {"Name": name, "ClassName": "Model", "Children": children}


def saloon():
    children = [
        # A lightweight playable interior: three walls, a split front, and broad doorway.
        part("InteriorFloor", [-49, 1.25, -20], [19, 0.5, 23], WOOD, "WoodPlanks"),
        part("BackWall", [-58.5, 7, -20], [1, 12, 24], SALOON_RED),
        part("NorthWall", [-49, 7, -31.5], [20, 12, 1], SALOON_RED),
        part("SouthWall", [-49, 7, -8.5], [20, 12, 1], SALOON_RED),
        part("FrontNorth", [-38.5, 7, -27], [1, 12, 10], SALOON_RED),
        part("FrontSouth", [-38.5, 7, -13], [1, 12, 10], SALOON_RED),
        part("FrontLintel", [-38.5, 11.5, -20], [1, 3, 4], SALOON_RED),
        part("Roof", [-49, 13.5, -20], [22, 1, 26], WOOD_DARK),
        part("SignBoard", [-37.8, 14.4, -20], [0.5, 3.2, 12], WOOD_LIGHT),
        part(
            "SwingDoorNorth",
            [-37.8, 3.1, -21.2],
            [0.35, 3.6, 1.4],
            WOOD_DARK,
            "Wood",
            CanCollide=False,
            CanQuery=False,
            CanTouch=False,
        ),
        part(
            "SwingDoorSouth",
            [-37.8, 3.1, -18.8],
            [0.35, 3.6, 1.4],
            WOOD_DARK,
            "Wood",
            CanCollide=False,
            CanQuery=False,
            CanTouch=False,
        ),
        part("WindowNorth", [-37.75, 6.2, -26.6], [0.4, 3.2, 4], WINDOW_DARK, "SmoothPlastic"),
        part("WindowSouth", [-37.75, 6.2, -13.4], [0.4, 3.2, 4], WINDOW_DARK, "SmoothPlastic"),
        part("InteriorBar", [-53, 3, -24], [2, 4, 9], WOOD_DARK, "Wood"),
        part("InteriorTable", [-49, 2.5, -14], [4, 3, 4], WOOD_LIGHT, "Wood"),
        part("BalconyFloor", [-35.8, 8.0, -20], [5.4, 1, 22], WOOD),
        part("BalconyRail", [-33.2, 9.7, -20], [0.35, 0.35, 20], WOOD_LIGHT),
        part("BalconyPostN", [-33.2, 9.5, -29], [0.45, 3.5, 0.45], WOOD_DARK),
        part("BalconyPostC", [-33.2, 9.5, -20], [0.45, 3.5, 0.45], WOOD_DARK),
        part("BalconyPostS", [-33.2, 9.5, -11], [0.45, 3.5, 0.45], WOOD_DARK),
    ]

    # Overlapping low-rise blocks behave like broad, roll-friendly stairs in Roblox.
    for index in range(8):
        top = 2.0 + index * 0.9
        children.append(
            part(
                f"BalconyStair{index + 1:02d}",
                [-35.8, (top + 1) / 2, -35 + index * 1.3],
                [5.2, top - 1, 2.0],
                WOOD,
            )
        )
    return model("Saloon", children)


def general_store():
    children = [
        part("Body", [-49, 6, 19], [20, 10, 20], STORE_OCHRE),
        part("Roof", [-49, 11.5, 19], [22, 1, 22], WOOD_DARK),
        part("FrontFacade", [-38.5, 7.4, 19], [1, 12.8, 22], STORE_OCHRE),
        part("SignBoard", [-37.8, 11.3, 19], [0.5, 2.8, 11], WOOD_LIGHT),
        part("Door", [-37.8, 3.6, 19], [0.45, 5.2, 3.8], WOOD_DARK, "Wood"),
        part("WindowNorth", [-37.75, 5.4, 13], [0.4, 3.2, 4], WINDOW_DARK, "SmoothPlastic"),
        part("WindowSouth", [-37.75, 5.4, 25], [0.4, 3.2, 4], WINDOW_DARK, "SmoothPlastic"),
        part("Porch", [-35.7, 1.45, 19], [5.5, 0.9, 19], WOOD),
        part("Awning", [-35.3, 7.2, 19], [6.2, 0.7, 19], WOOD_DARK),
        part("AwningPostN", [-33, 4.2, 11], [0.45, 6, 0.45], WOOD_DARK),
        part("AwningPostS", [-33, 4.2, 27], [0.45, 6, 0.45], WOOD_DARK),
    ]
    return model("GeneralStore", children)


def sheriff_building():
    children = [
        part("Body", [49, 6.5, -18], [20, 11, 20], SHERIFF_GRAY),
        part("Roof", [49, 12.5, -18], [22, 1, 22], WOOD_DARK),
        part("FrontFacade", [38.5, 8.2, -18], [1, 14.4, 22], SHERIFF_GRAY),
        part("SignBoard", [37.8, 12.2, -18], [0.5, 2.8, 10], WOOD_LIGHT),
        part("Door", [37.8, 3.6, -18], [0.45, 5.2, 3.8], WOOD_DARK, "Wood"),
        part("WindowNorth", [37.75, 5.6, -24], [0.4, 3.2, 4], WINDOW_DARK, "SmoothPlastic"),
        part("WindowSouth", [37.75, 5.6, -12], [0.4, 3.2, 4], WINDOW_DARK, "SmoothPlastic"),
        part("BalconyFloor", [35.8, 7.0, -18], [5.4, 1, 18], WOOD),
        part("BalconyRail", [33.2, 8.7, -18], [0.35, 0.35, 16], WOOD_LIGHT),
        part("BalconyPostN", [33.2, 8.5, -25], [0.45, 3.5, 0.45], WOOD_DARK),
        part("BalconyPostS", [33.2, 8.5, -11], [0.45, 3.5, 0.45], WOOD_DARK),
    ]

    for index in range(7):
        top = 2.0 + index * 0.9
        children.append(
            part(
                f"BalconyStair{index + 1:02d}",
                [35.8, (top + 1) / 2, -34 + index * 1.3],
                [5.2, top - 1, 2.0],
                WOOD,
            )
        )
    return model("Sheriff", children)


def stable():
    children = [
        part("BarnBody", [49, 5.5, 20], [20, 9, 20], STABLE_BROWN),
        part("BarnRoof", [49, 10.5, 20], [22, 1, 22], WOOD_DARK),
        part("OpenDoor", [38.7, 4.2, 20], [0.35, 6.4, 7], WINDOW_DARK, "SmoothPlastic"),
        part("LoftDoor", [38.65, 8.2, 20], [0.3, 2.2, 4.5], WOOD_DARK),
        part("StableAwning", [35.8, 6.7, 20], [6.2, 0.7, 18], WOOD),
        part("AwningPostN", [33, 3.8, 13], [0.45, 5.8, 0.45], WOOD_DARK),
        part("AwningPostS", [33, 3.8, 27], [0.45, 5.8, 0.45], WOOD_DARK),
        part("HayBaleA", [33, 2, 16], [5, 2, 4], DUST_LIGHT, "Fabric"),
        part("HayBaleB", [34, 3.2, 23], [4, 4.4, 5], DUST_LIGHT, "Fabric"),
    ]
    return model("Stable", children)


def lobby():
    children = [
        part("LobbyPlatform", [0, 0, -66], [56, 2, 30], DUST_LIGHT, "Sandstone"),
        part("LobbyBridge", [0, 1.25, -53], [20, 0.5, 5], WOOD, "WoodPlanks"),
        part("StationBody", [0, 7, -77], [40, 12, 8], LOBBY_BLUE, "WoodPlanks"),
        part("StationRoof", [0, 13.5, -77], [44, 1, 10], WOOD_DARK, "Wood"),
        part("StationPorch", [0, 1.35, -72], [42, 0.7, 6], WOOD, "WoodPlanks"),
        part("StationAwning", [0, 8.5, -72.5], [42, 0.7, 6], WOOD_DARK, "Wood"),
        part("StationPostWest", [-18, 4.8, -71], [0.6, 7, 0.6], WOOD_DARK, "Wood"),
        part("StationPostMidWest", [-6, 4.8, -71], [0.6, 7, 0.6], WOOD_DARK, "Wood"),
        part("StationPostMidEast", [6, 4.8, -71], [0.6, 7, 0.6], WOOD_DARK, "Wood"),
        part("StationPostEast", [18, 4.8, -71], [0.6, 7, 0.6], WOOD_DARK, "Wood"),
        part("StationSign", [0, 11.4, -72.2], [16, 3.2, 0.5], WOOD_LIGHT, "Wood"),
        part("GatePostWest", [-10.5, 5, -51], [1.2, 8, 1.2], WOOD_DARK, "Wood"),
        part("GatePostEast", [10.5, 5, -51], [1.2, 8, 1.2], WOOD_DARK, "Wood"),
        part("GateHeader", [0, 8.5, -51], [22, 1.4, 1.4], WOOD_LIGHT, "Wood"),
        part("GateBadge", [0, 10.1, -51], [8, 2.2, 0.7], SALOON_RED, "Wood"),
        part("GateDoor", [0, 4.4, -50.5], [9, 7.5, 1], WOOD_DARK, "Wood"),
        part("BenchWestSeat", [-15, 2.2, -62], [8, 0.6, 2], WOOD_LIGHT, "Wood"),
        part("BenchWestBack", [-15, 3.3, -63], [8, 2.6, 0.5], WOOD, "Wood"),
        part("BenchEastSeat", [15, 2.2, -62], [8, 0.6, 2], WOOD_LIGHT, "Wood"),
        part("BenchEastBack", [15, 3.3, -63], [8, 2.6, 0.5], WOOD, "Wood"),
        part("WeaponRack", [-20, 4.0, -73], [5, 5, 1], WOOD_DARK, "Wood"),
        part("PracticeBoard", [20, 4.5, -73], [6, 6, 0.7], WOOD_LIGHT, "Wood"),
        barrel("LobbyBarrelWest", [-23, 2.8, -56]),
        barrel("LobbyBarrelEast", [23, 2.8, -56]),
        model("ArenaEntrance", [
            part("EntryPedestal", [0, 2.55, -53.5], [4.8, 3, 1.2], WOOD, "Wood",
                 children=[{
                     "Name": "EnterPrompt",
                     "ClassName": "ProximityPrompt",
                     "Properties": {
                         "ActionText": "Enter Arena",
                         "ObjectText": "Quick Draw Gate",
                         "HoldDuration": 0,
                         "KeyboardKeyCode": "F",
                         "GamepadKeyCode": "ButtonX",
                         "MaxActivationDistance": 10,
                         "RequiresLineOfSight": False,
                     },
                 }]),
            part("EntryGoldRail", [0, 4.1, -53.7], [5.2, 0.22, 0.28], DUST_LIGHT, "Metal",
                 CanCollide=False, CanQuery=False, CanTouch=False),
        ]),
        model("SettingsAccess", [
            part("SettingsBoard", [20, 3.25, -70], [5.5, 4.5, 0.65], WOOD_DARK, "Wood",
                 children=[{
                     "Name": "SettingsPrompt",
                     "ClassName": "ProximityPrompt",
                     "Properties": {
                         "ActionText": "Open Settings",
                         "ObjectText": "Town Settings",
                         "HoldDuration": 0,
                         "KeyboardKeyCode": "G",
                         "GamepadKeyCode": "ButtonX",
                         "MaxActivationDistance": 9,
                         "RequiresLineOfSight": False,
                     },
                 }]),
        ]),
    ]

    lobby_spawns = [
        (-16, -66),
        (-8, -61),
        (0, -67),
        (8, -61),
        (16, -66),
        (0, -57),
    ]
    for index, (x, z) in enumerate(lobby_spawns, start=1):
        children.append(lobby_spawn(f"LobbySpawn{index:02d}", [x, 1.1, z]))

    children.extend([
        part("SpawnZoneFloor", [0, 1.05, -63], [44, 0.1, 17], DUST_LIGHT, "Sandstone"),
        part("LobbyBoundaryWest", [-28, 27, -66], [2, 52, 34], WOOD_DARK,
             "SmoothPlastic", Transparency=1, CanCollide=True, CanQuery=False, CanTouch=False),
        part("LobbyBoundaryEast", [28, 27, -66], [2, 52, 34], WOOD_DARK,
             "SmoothPlastic", Transparency=1, CanCollide=True, CanQuery=False, CanTouch=False),
        part("LobbyBoundaryBack", [0, 27, -82], [58, 52, 2], WOOD_DARK,
             "SmoothPlastic", Transparency=1, CanCollide=True, CanQuery=False, CanTouch=False),
        part("LobbyBoundaryFront", [0, 27, -49.5], [58, 52, 2], WOOD_DARK,
             "SmoothPlastic", Transparency=1, CanCollide=True, CanQuery=False, CanTouch=False),
    ])

    # Open fencing keeps the overlook readable without creating a closed box.
    for x in (-26, 26):
        children.extend(
            [
                part(f"SideRail{x}A", [x, 2.4, -59], [0.5, 0.5, 14], WOOD_LIGHT, "Wood"),
                part(f"SideRail{x}B", [x, 3.7, -59], [0.5, 0.5, 14], WOOD_LIGHT, "Wood"),
                part(f"SidePost{x}North", [x, 2.9, -65], [0.7, 4, 0.7], WOOD_DARK, "Wood"),
                part(f"SidePost{x}South", [x, 2.9, -53], [0.7, 4, 0.7], WOOD_DARK, "Wood"),
            ]
        )

    children.extend(
        [
            lantern("LobbyLanternWest", [-10, 1, -53], 7.5),
            lantern("LobbyLanternEast", [10, 1, -53], 7.5),
            cactus("LobbyCactusWest", [-22, 1, -68], 5.5),
            cactus("LobbyCactusEast", [22, 1, -68], 6.5),
        ]
    )
    return model("Lobby", children)


def environment():
    return model(
        "Environment",
        [
            part("DustGround", [0, 0, 0], [140, 2, 96], DUST, "Sand"),
            part("MainStreet", [0, 1.04, 0], [62, 0.08, 90], DUST_LIGHT, "Sand"),
            part("WestBoardwalk", [-34.5, 1.3, 0], [7, 0.6, 88], WOOD, "WoodPlanks"),
            part("EastBoardwalk", [34.5, 1.3, 0], [7, 0.6, 88], WOOD, "WoodPlanks"),
            part("NorthCanyon", [0, 7, -47], [140, 12, 2], SANDSTONE, "Sandstone"),
            part("SouthCanyon", [0, 7, 47], [140, 12, 2], SANDSTONE, "Sandstone"),
            part("WestCanyon", [-69, 7, 0], [2, 12, 96], SANDSTONE, "Sandstone"),
            part("EastCanyon", [69, 7, 0], [2, 12, 96], SANDSTONE, "Sandstone"),
            part("NorthStreetGateWest", [-25, 4, -43], [18, 6, 3], SANDSTONE, "Sandstone"),
            part("NorthStreetGateEast", [25, 4, -43], [18, 6, 3], SANDSTONE, "Sandstone"),
            part("SouthStreetGateWest", [-25, 4, 43], [18, 6, 3], SANDSTONE, "Sandstone"),
            part("SouthStreetGateEast", [25, 4, 43], [18, 6, 3], SANDSTONE, "Sandstone"),
            part("ArenaBoundaryNorth", [0, 28, -46], [140, 54, 2], SANDSTONE,
                 "SmoothPlastic", Transparency=1, CanCollide=True, CanQuery=False, CanTouch=False),
            part("ArenaBoundarySouth", [0, 28, 46], [140, 54, 2], SANDSTONE,
                 "SmoothPlastic", Transparency=1, CanCollide=True, CanQuery=False, CanTouch=False),
            part("ArenaBoundaryWest", [-68, 28, 0], [2, 54, 96], SANDSTONE,
                 "SmoothPlastic", Transparency=1, CanCollide=True, CanQuery=False, CanTouch=False),
            part("ArenaBoundaryEast", [68, 28, 0], [2, 54, 96], SANDSTONE,
                 "SmoothPlastic", Transparency=1, CanCollide=True, CanQuery=False, CanTouch=False),
        ],
    )


def street_cover():
    children = [
        part("WaterTrough", [0, 2.1, 0], [12, 2.2, 5], WOOD_DARK, "Wood"),
        part("NorthBarricade", [-7, 2.5, -19], [11, 3, 1.5], WOOD, "WoodPlanks"),
        part("SouthBarricade", [8, 2.5, 19], [11, 3, 1.5], WOOD, "WoodPlanks"),
        part("WestAlleyCover", [-25, 3, 3], [3, 4, 8], WOOD_LIGHT, "WoodPlanks"),
        part("EastAlleyCover", [25, 3, -3], [3, 4, 8], WOOD_LIGHT, "WoodPlanks"),
        part("Crate01", [-10, 2.5, -7], [5, 3, 5], WOOD_LIGHT),
        part("Crate02", [-7, 4.0, -7], [3, 6, 3], WOOD),
        part("Crate03", [13, 2.5, 8], [5, 3, 5], WOOD_LIGHT),
        part("Crate04", [10, 3.5, 9], [3, 5, 3], WOOD),
        part("Crate05", [-28, 2.5, 32], [5, 3, 5], WOOD_LIGHT),
        part("Crate06", [27, 2.5, -34], [5, 3, 5], WOOD_LIGHT),
        part("Crate07", [-61, 2.5, 4], [5, 3, 5], WOOD),
        part("Crate08", [61, 2.5, -4], [5, 3, 5], WOOD),
        barrel("Barrel01", [-15, 2.8, 17]),
        barrel("Barrel02", [-18, 2.8, 18]),
        barrel("Barrel03", [17, 2.8, -16]),
        barrel("Barrel04", [20, 2.8, -17]),
        barrel("Barrel05", [-31, 2.8, -4]),
        barrel("Barrel06", [31, 2.8, 5]),
        barrel("Barrel07", [-61, 2.8, -30]),
        barrel("Barrel08", [61, 2.8, 30]),
    ]

    # Stable corral with gaps at both ends so the route never becomes a dead end.
    for z_position in (32, 40):
        children.append(part(f"CorralRail{z_position}A", [51, 2.2, z_position], [22, 0.45, 0.45], WOOD_LIGHT))
        children.append(part(f"CorralRail{z_position}B", [51, 3.5, z_position], [22, 0.45, 0.45], WOOD_LIGHT))
    for x_position in (40, 51, 62):
        children.append(part(f"CorralPost{x_position}", [x_position, 2.8, 36], [0.6, 4.2, 0.6], WOOD_DARK))

    # Back-lane fence segments break sightlines without sealing the loop.
    children.extend(
        [
            part("WestBackFenceNorth", [-63, 2.5, -14], [1, 3, 12], WOOD_LIGHT),
            part("WestBackFenceSouth", [-63, 2.5, 17], [1, 3, 11], WOOD_LIGHT),
            part("EastBackFenceNorth", [63, 2.5, -15], [1, 3, 11], WOOD_LIGHT),
            part("EastBackFenceSouth", [63, 2.5, 8], [1, 3, 10], WOOD_LIGHT),
        ]
    )
    return model("CoverAndProps", children)


def town_decor():
    children = [
        lantern("LampWestNorth", [-31, 1.6, -30], 7),
        lantern("LampWestCenter", [-31, 1.6, 0], 7),
        lantern("LampWestSouth", [-31, 1.6, 30], 7),
        lantern("LampEastNorth", [31, 1.6, -30], 7),
        lantern("LampEastCenter", [31, 1.6, 0], 7),
        lantern("LampEastSouth", [31, 1.6, 30], 7),
        wagon("StreetWagon", [12, 1, -29]),
        part("HitchPostWestA", [-29, 3, 9], [0.7, 4, 0.7], WOOD_DARK, "Wood"),
        part("HitchPostWestB", [-29, 3, 17], [0.7, 4, 0.7], WOOD_DARK, "Wood"),
        part("HitchRailWest", [-29, 3.6, 13], [0.55, 0.55, 8], WOOD_LIGHT, "Wood"),
        part("HitchPostEastA", [29, 3, -8], [0.7, 4, 0.7], WOOD_DARK, "Wood"),
        part("HitchPostEastB", [29, 3, 0], [0.7, 4, 0.7], WOOD_DARK, "Wood"),
        part("HitchRailEast", [29, 3.6, -4], [0.55, 0.55, 8], WOOD_LIGHT, "Wood"),
        part("RockNorthWest", [-21, 2, -40], [7, 2, 5], SANDSTONE, "Slate", Orientation=[0, 18, 8]),
        part("RockSouthEast", [22, 2, 39], [6, 2.2, 5], SANDSTONE, "Slate", Orientation=[0, -20, -6]),
        part("NoticeBoard", [29, 5, -19], [0.6, 5.5, 6], WOOD_LIGHT, "Wood"),
        part("NoticePostA", [29, 2.6, -21], [0.7, 3.2, 0.7], WOOD_DARK, "Wood"),
        part("NoticePostB", [29, 2.6, -17], [0.7, 3.2, 0.7], WOOD_DARK, "Wood"),
        part("HayStackWest", [-28, 2.3, -10], [4.5, 2.6, 3.5], DUST_LIGHT, "Fabric"),
        part("HayStackEast", [27, 2.3, 25], [4.5, 2.6, 3.5], DUST_LIGHT, "Fabric"),
    ]
    return model("TownDecor", children)


def spawns():
    return model(
        "Spawns",
        [
            combat_marker("SpawnNorthWestBack", [-63, 1.5, -38]),
            combat_marker("SpawnNorthStreetWest", [-27, 1.5, -39]),
            combat_marker("SpawnNorthStreetEast", [27, 1.5, -39]),
            combat_marker("SpawnNorthEastBack", [63, 1.5, -38]),
            combat_marker("SpawnEastAlley", [58, 1.5, 0]),
            combat_marker("SpawnSouthEastBack", [63, 1.5, 38]),
            combat_marker("SpawnSouthStreetEast", [27, 1.5, 39]),
            combat_marker("SpawnSouthStreetWest", [-27, 1.5, 39]),
            combat_marker("SpawnSouthWestBack", [-63, 1.5, 38]),
            combat_marker("SpawnWestAlley", [-58, 1.5, 0]),
        ],
    )


def build_arena():
    return {
        "ClassName": "Model",
        "Children": [
            environment(),
            lobby(),
            model("Buildings", [saloon(), general_store(), sheriff_building(), stable()]),
            street_cover(),
            town_decor(),
            spawns(),
        ],
    }


def main():
    arena = build_arena()
    OUTPUT.write_text(json.dumps(arena, indent=2) + "\n", encoding="utf-8")

    def walk(instance):
        yield instance
        for child in instance.get("Children", []):
            yield from walk(child)

    instances = list(walk(arena))
    parts = [item for item in instances if item.get("ClassName") == "Part"]
    spawn_locations = [item for item in instances if item.get("ClassName") == "SpawnLocation"]
    print(f"Generated {OUTPUT}")
    print(f"Parts: {len(parts)}")
    print(f"SpawnLocations: {len(spawn_locations)}")


if __name__ == "__main__":
    main()
