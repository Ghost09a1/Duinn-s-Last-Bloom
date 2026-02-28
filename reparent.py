import sys
import re

file_path = r"c:\Users\Ghost\Desktop\Duinn's Last Bloom\scenes\main\TavernPrototype.tscn"
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add NavigationMesh SubResource
if '[sub_resource type="NavigationMesh" id="NavigationMesh_tavern"]' not in content:
    content = content.replace('[node name="TavernPrototype" type="Node3D"]',
        '[sub_resource type="NavigationMesh" id="NavigationMesh_tavern"]\n\n[node name="TavernPrototype" type="Node3D"]')

# Add NavigationRegion3D Node
nav_node_str = '[node name="NavigationRegion3D" type="NavigationRegion3D" parent="."]\nnavigation_mesh = SubResource("NavigationMesh_tavern")\n\n'
if '[node name="NavigationRegion3D" type="NavigationRegion3D"' not in content:
    content = content.replace('[node name="FloorCollider" type="StaticBody3D" parent="."]',
        nav_node_str + '[node name="FloorCollider" type="StaticBody3D" parent="."]')

nodes_to_reparent = [
    'FloorCollider', 'Floor', 'WallNorth', 'WallSouth', 'WallWest', 'WallEast',
    'DecoRoot', 'FurnRoot', 'TresenBase', 'StationDrinks', 'StationFood', 'ServiceBell',
    'BroomStation', 'TowerWindow'
]

lines = content.split('\n')
for i, line in enumerate(lines):
    for node in nodes_to_reparent:
        if line.startswith(f'[node name="{node}" ') and 'parent="."' in line:
            lines[i] = line.replace('parent="."', 'parent="NavigationRegion3D"')

content = '\n'.join(lines)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("SUCCESS")
