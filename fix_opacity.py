import re
import os
from pathlib import Path

def fix_with_opacity(file_path):
    """Fix deprecated withOpacity calls in a Dart file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Pattern to match .withOpacity(number)
    # This regex captures the opacity value
    pattern = r'\.withOpacity\(([0-9.]+)\)'
    
    def replace_opacity(match):
        opacity_value = match.group(1)
        return f'.withValues(alpha: {opacity_value})'
    
    content = re.sub(pattern, replace_opacity, content)
    
    # Only write if changes were made
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    lib_path = Path(r'c:\Flutter_project\iBrgy\lib')
    
    dart_files = list(lib_path.rglob('*.dart'))
    
    fixed_count = 0
    for dart_file in dart_files:
        if fix_with_opacity(dart_file):
            print(f'Fixed: {dart_file}')
            fixed_count += 1
    
    print(f'\nTotal files fixed: {fixed_count}')

if __name__ == '__main__':
    main()
