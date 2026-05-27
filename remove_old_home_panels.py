from pathlib import Path
import re

p = Path("lib/views/home/home_screen.dart")
s = p.read_text(encoding="utf-8")

# 1) Supprimer l'appel à l'ancienne bannière approval dans build()
s = re.sub(
    r"\s*if \(_accountStatus != 'approved'\) \.\.\.\[\s*_approvalBanner\(\),\s*SizedBox\(height: 12\.h\),\s*\],",
    "",
    s,
)

# 2) Remplacer le gros empty panel offline par rien
s = re.sub(
    r"\s*_emptyPanel\(\s*Icons\.radio_button_checked_rounded,\s*'Ready to go online',\s*'Start receiving ride and courier requests instantly\.',\s*\),\s*SizedBox\(height: 18\.h\),",
    "",
    s,
)

# 3) Remplacer le gros empty panel online waiting par rien
s = re.sub(
    r"\s*_emptyPanel\(\s*Icons\.radar_rounded,\s*'Waiting for requests',\s*'You are online\. New ride and courier requests will appear here\.',\s*\),\s*SizedBox\(height: 18\.h\),",
    "",
    s,
)

p.write_text(s, encoding="utf-8")
