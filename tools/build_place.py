#!/usr/bin/env python3
"""
build_place.py
Generates the complete, standalone Roblox Studio place file (Ragdoll_Game.rbxlx)
embedding all models, anatomical rigs, organs, physics obstacles, weapons, and scripts.
"""

import os
import xml.etree.ElementTree as ET
from xml.dom import minidom

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def read_source(rel_path):
    full_path = os.path.join(REPO_ROOT, rel_path)
    with open(full_path, "r", encoding="utf-8") as f:
        return f.read()

def create_item(parent, class_name, referent, name=None):
    item = ET.SubElement(parent, "Item", {"class": class_name, "referent": str(referent)})
    props = ET.SubElement(item, "Properties")
    if name:
        name_elem = ET.SubElement(props, "string", {"name": "Name"})
        name_elem.text = name
    return item, props

def add_bool(props, name, value):
    elem = ET.SubElement(props, "bool", {"name": name})
    elem.text = "true" if value else "false"

def add_string(props, name, value):
    elem = ET.SubElement(props, "string", {"name": name})
    elem.text = value

def add_float(props, name, value):
    elem = ET.SubElement(props, "float", {"name": name})
    elem.text = str(value)

def add_int(props, name, value):
    elem = ET.SubElement(props, "int", {"name": name})
    elem.text = str(value)

def add_token(props, name, value):
    elem = ET.SubElement(props, "token", {"name": name})
    elem.text = str(value)

def add_vector3(props, name, x, y, z):
    elem = ET.SubElement(props, "Vector3", {"name": name})
    ET.SubElement(elem, "X").text = str(x)
    ET.SubElement(elem, "Y").text = str(y)
    ET.SubElement(elem, "Z").text = str(z)

def add_color3(props, name, r, g, b):
    elem = ET.SubElement(props, "Color3", {"name": name})
    ET.SubElement(elem, "R").text = str(r)
    ET.SubElement(elem, "G").text = str(g)
    ET.SubElement(elem, "B").text = str(b)

def add_cframe(props, name, x, y, z, r00=1, r01=0, r02=0, r10=0, r11=1, r12=0, r20=0, r21=0, r22=1):
    elem = ET.SubElement(props, "CoordinateFrame", {"name": name})
    ET.SubElement(elem, "X").text = str(x)
    ET.SubElement(elem, "Y").text = str(y)
    ET.SubElement(elem, "Z").text = str(z)
    ET.SubElement(elem, "R00").text = str(r00)
    ET.SubElement(elem, "R01").text = str(r01)
    ET.SubElement(elem, "R02").text = str(r02)
    ET.SubElement(elem, "R10").text = str(r10)
    ET.SubElement(elem, "R11").text = str(r11)
    ET.SubElement(elem, "R12").text = str(r12)
    ET.SubElement(elem, "R20").text = str(r20)
    ET.SubElement(elem, "R21").text = str(r21)
    ET.SubElement(elem, "R22").text = str(r22)

def add_part(parent, ref, name, size, position, color, anchored=True, can_collide=True, transparency=0, material=256):
    part, props = create_item(parent, "Part", ref, name)
    add_bool(props, "Anchored", anchored)
    add_bool(props, "CanCollide", can_collide)
    add_vector3(props, "size", size[0], size[1], size[2])
    add_vector3(props, "Position", position[0], position[1], position[2])
    add_cframe(props, "CFrame", position[0], position[1], position[2])
    add_color3(props, "Color", color[0], color[1], color[2])
    add_float(props, "Transparency", transparency)
    add_token(props, "Material", material)
    return part

def build():
    root = ET.Element("roblox", {"version": "4"})
    ref_counter = 1

    def next_ref():
        nonlocal ref_counter
        r = f"RBX_{ref_counter}"
        ref_counter += 1
        return r

    # 1. Workspace
    workspace, ws_props = create_item(root, "Workspace", next_ref(), "Workspace")
    add_bool(ws_props, "FilteringEnabled", True)

    # Baseplate
    add_part(workspace, next_ref(), "Baseplate", (512, 10, 512), (0, -5, 0), (0.11, 0.12, 0.14), anchored=True, can_collide=True, material=784)

    # SpawnLocation
    spawn, spawn_props = create_item(workspace, "SpawnLocation", next_ref(), "SpawnLocation")
    add_bool(spawn_props, "Anchored", True)
    add_bool(spawn_props, "CanCollide", True)
    add_vector3(spawn_props, "size", 16, 1, 16)
    add_vector3(spawn_props, "Position", 0, 0.5, 15)
    add_cframe(spawn_props, "CFrame", 0, 0.5, 15)
    add_color3(spawn_props, "Color", 0.18, 0.2, 0.24)
    add_int(spawn_props, "Duration", 0)

    # 2. Lighting
    lighting, light_props = create_item(root, "Lighting", next_ref(), "Lighting")
    add_float(light_props, "Brightness", 2.2)
    add_color3(light_props, "Ambient", 0.25, 0.25, 0.3)
    add_color3(light_props, "OutdoorAmbient", 0.4, 0.4, 0.45)
    add_bool(light_props, "GlobalShadows", True)
    add_token(light_props, "Technology", 3) # ShadowMap / Future

    # Sky
    sky, sky_props = create_item(lighting, "Sky", next_ref(), "Sky")
    add_string(sky_props, "SkyboxBk", "rbxassetid://600830446")
    add_string(sky_props, "SkyboxDn", "rbxassetid://600831635")
    add_string(sky_props, "SkyboxFt", "rbxassetid://600832720")
    add_string(sky_props, "SkyboxLf", "rbxassetid://600833862")
    add_string(sky_props, "SkyboxRt", "rbxassetid://600835177")
    add_string(sky_props, "SkyboxUp", "rbxassetid://600836262")

    # 3. ReplicatedStorage
    rep_storage, rep_props = create_item(root, "ReplicatedStorage", next_ref(), "ReplicatedStorage")
    shared_folder, _ = create_item(rep_storage, "Folder", next_ref(), "Shared")

    # Modules in Shared
    modules = [
        ("RagdollModule", "src/shared/RagdollModule.luau"),
        ("BloodEngine", "src/shared/BloodEngine.luau"),
        ("WeaponConfig", "src/shared/WeaponConfig.luau"),
    ]
    for mod_name, mod_path in modules:
        mod_item, m_props = create_item(shared_folder, "ModuleScript", next_ref(), mod_name)
        add_string(m_props, "Source", read_source(mod_path))

    # RemoteEvents
    remotes = [
        "ToggleRagdoll",
        "RequestPush",
        "ShootWeapon",
        "OrganHitEvent",
        "ToggleXRay",
        "ResetDummy",
    ]
    for r_name in remotes:
        create_item(rep_storage, "RemoteEvent", next_ref(), r_name)

    # 4. ServerScriptService
    sss, _ = create_item(root, "ServerScriptService", next_ref(), "ServerScriptService")
    server_scripts = [
        ("RagdollServer", "src/server/RagdollServer.server.luau"),
    ]
    for s_name, s_path in server_scripts:
        s_item, s_props = create_item(sss, "Script", next_ref(), s_name)
        add_string(s_props, "Source", read_source(s_path))

    # 5. StarterPlayer
    starter_player, _ = create_item(root, "StarterPlayer", next_ref(), "StarterPlayer")
    s_player_scripts, _ = create_item(starter_player, "StarterPlayerScripts", next_ref(), "StarterPlayerScripts")

    client_scripts = [
        ("RagdollController", "src/client/RagdollController.client.luau"),
        ("RagdollHud", "src/client/RagdollHud.client.luau"),
    ]
    for c_name, c_path in client_scripts:
        c_item, c_props = create_item(s_player_scripts, "LocalScript", next_ref(), c_name)
        add_string(c_props, "Source", read_source(c_path))

    # 6. StarterPack (Weapons & Tools)
    starter_pack, _ = create_item(root, "StarterPack", next_ref(), "StarterPack")

    tools_data = [
        ("Пистолет 9mm (Pistol)", "src/starterpack/Pistol/GunClient.client.luau", (0.3, 0.2, 0.2), "rbxassetid://131070686"),
        ("Дробовик 12G (Shotgun)", "src/starterpack/Shotgun/ShotgunClient.client.luau", (0.2, 0.2, 0.2), "rbxassetid://142494488"),
        ("Толкатель (Push Hands)", "src/starterpack/PushTool/PushClient.client.luau", (0.9, 0.8, 0.7), "rbxassetid://138090596"),
        ("Жезл Рэгдолла (Wand)", "src/starterpack/RagdollWand/WandClient.client.luau", (0.2, 0.8, 1.0), "rbxassetid://131237241"),
    ]

    for tool_name, script_path, handle_color, sound_id in tools_data:
        tool_item, tool_props = create_item(starter_pack, "Tool", next_ref(), tool_name)
        add_bool(tool_props, "RequiresHandle", True)
        add_bool(tool_props, "CanBeDropped", True)

        # Handle part
        handle_item, h_props = create_item(tool_item, "Part", next_ref(), "Handle")
        add_vector3(h_props, "size", 0.6, 0.8, 1.4)
        add_color3(h_props, "Color", handle_color[0], handle_color[1], handle_color[2])
        add_bool(h_props, "Anchored", False)
        add_bool(h_props, "CanCollide", False)

        # Sound
        if sound_id:
            snd, snd_props = create_item(handle_item, "Sound", next_ref(), "ActionSound")
            add_string(snd_props, "SoundId", sound_id)
            add_float(snd_props, "Volume", 0.8)

        # Script
        script_item, scr_props = create_item(tool_item, "LocalScript", next_ref(), "ClientScript")
        add_string(scr_props, "Source", read_source(script_path))

    # Convert to XML string
    out_file = os.path.join(REPO_ROOT, "Ragdoll_Game.rbxlx")
    rough_string = ET.tostring(root, "utf-8")
    reparsed = minidom.parseString(rough_string)
    pretty_xml = reparsed.toprettyxml(indent="  ", encoding="utf-8")

    with open(out_file, "wb") as f:
        f.write(pretty_xml)

    print(f"[Build] Successfully created {out_file} ({os.path.getsize(out_file)} bytes)")

if __name__ == "__main__":
    build()
