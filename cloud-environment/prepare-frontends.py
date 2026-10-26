import json
import pathlib
import re
import shutil

root = pathlib.Path('/workspace/springboot-movie')
out = pathlib.Path('/workspace/movie-env')
for name in ('vue-app', 'vue-admin', 'vue-worker'):
    dest = out / name
    dest.mkdir(exist_ok=True)
    shutil.copy2(root / name / 'package.json', dest / 'package.json')
    lock = json.loads((root / name / 'package-lock.json').read_text())
    def normalize(value):
        if isinstance(value, dict):
            for key, item in value.items():
                if key == 'resolved' and isinstance(item, str) and 'registry.npm.taobao.org/' in item:
                    item = re.sub(r'https?://registry.npm.taobao.org/(.+)/download/', r'https://registry.npmjs.org/\1/-/', item)
                    value[key] = re.sub(r'(/-/)@[^/]+/', r'\1', item)
                else:
                    normalize(item)
        elif isinstance(value, list):
            for item in value:
                normalize(item)
    normalize(lock)
    (dest / 'package-lock.json').write_text(json.dumps(lock, indent=2) + '\n')
    for folder in ('src', 'public'):
        target = dest / folder
        if not target.exists():
            target.symlink_to(root / name / folder, target_is_directory=True)
    (dest / 'vue.config.js').write_text('module.exports = { configureWebpack: { resolve: { symlinks: false } } };\n')
