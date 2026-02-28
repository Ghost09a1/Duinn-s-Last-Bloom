import os
import re

file_path = r"c:\Users\Ghost\Desktop\Duinn's Last Bloom\scenes\main\TavernPrototype.tscn"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Finde alle Nodes, die direkt unter NavigationRegion3D liegen
nav_children = set()
pattern = r'\[node name="([^"]+)" [^\]]*parent="NavigationRegion3D"\]'
for match in re.finditer(pattern, content):
    nav_children.add(match.group(1))

print(f"Befinde folgende Nav-Children zum Pfad anpassen: {nav_children}")

# Aktualisiere die Parents aller echten Children dieser Nodes
# Wenn ein Node parent="X" hat und X in nav_children ist, wird es zu parent="NavigationRegion3D/X"
new_content = ""
lines = content.split('\n')
updated_count = 0

for line in lines:
    if line.startswith('[node '):
        match = re.search(r'parent="([^"]+)"', line)
        if match:
            old_parent = match.group(1)
            # Wenn das Parent in der Liste der direkten Unterknoten ist, pack das NavigationRegion3D Prefix davor
            if old_parent in nav_children:
                new_parent = f"NavigationRegion3D/{old_parent}"
                line = line.replace(f'parent="{old_parent}"', f'parent="{new_parent}"')
                updated_count += 1
            # Wenn es bereits ein relativer Pfad ist, prüfe ob das erste Element ein nav_child ist
            elif "/" in old_parent and not old_parent.startswith("NavigationRegion3D/"):
                first_part = old_parent.split("/")[0]
                if first_part in nav_children:
                    new_parent = f"NavigationRegion3D/{old_parent}"
                    line = line.replace(f'parent="{old_parent}"', f'parent="{new_parent}"')
                    updated_count += 1
        
    new_content += line + "\n"

with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_content.strip() + "\n")

print(f"TavernPrototype.tscn erfolgreich repariert! {updated_count} Parent-Pfade wurden auf 'NavigationRegion3D/...' geupdatet.")
