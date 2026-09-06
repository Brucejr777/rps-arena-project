"""Combine the entire RPS Arena project into a single .txt file for AI context."""

import os

ROOT = os.path.dirname(os.path.abspath(__file__))

# Directories/files to always skip
SKIP_DIRS = {
    '.git', '.dart_tool', '.idea', 'build', 'android', 'ios', 'web',
    'node_modules', '.freebuff', 'design', 'docs', 'test',
    'backend/test', '.flutter-plugins-dependencies',
}

# File extensions to include
INCLUDE_EXTS = {
    '.dart', '.js', '.yaml', '.json', '.md', '.sql', '.txt',
}

# Specific files to include from backend root
BACKEND_INCLUDE = {
    'server.js', 'package.json',
}

# Specific files to skip even if extension matches
SKIP_FILES = {
    'pubspec.lock', 'package-lock.json', 'rps_arena.iml', '.metadata',
    'combine_project.py',
}

def should_include(rel_path: str) -> bool:
    parts = rel_path.replace('\\', '/').split('/')

    # Skip any directory in the skip list
    for part in parts[:-1]:
        if part in SKIP_DIRS:
            return False

    basename = parts[-1]
    if basename in SKIP_FILES:
        return False

    _, ext = os.path.splitext(basename)
    if ext not in INCLUDE_EXTS:
        return False

    return True

def main():
    output_path = os.path.join(ROOT, 'project_context.txt')
    lines = []
    file_count = 0

    for dirpath, dirnames, filenames in os.walk(ROOT):
        # Prune skipped directories in-place so os.walk won't descend
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]

        for fname in sorted(filenames):
            full_path = os.path.join(dirpath, fname)
            rel_path = os.path.relpath(full_path, ROOT).replace('\\', '/')

            if not should_include(rel_path):
                continue

            try:
                with open(full_path, 'r', encoding='utf-8', errors='replace') as f:
                    content = f.read()
            except Exception:
                continue

            lines.append(f'{"=" * 80}')
            lines.append(f'FILE: {rel_path}')
            lines.append(f'{"=" * 80}')
            lines.append(content)
            lines.append('')
            file_count += 1

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))

    size_kb = os.path.getsize(output_path) / 1024
    print(f'Wrote {file_count} files ({size_kb:.0f} KB) -> {output_path}')

if __name__ == '__main__':
    main()
