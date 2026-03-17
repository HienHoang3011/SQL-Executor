import os

init_path = '/Users/hieudevdut/Library/CloudStorage/GoogleDrive-hieudevnguyen.work@gmail.com/My Drive/Projects/SQL-Executor/backend/sql/init.sql'
with open(init_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

out_lines = []
for i, line in enumerate(lines):
    if '-- 2. DML - Seed Data' in line:
        # Also remove the separator line before it if it exists
        if i > 0 and '-- ====' in lines[i-1]:
            out_lines.pop()
        break
    out_lines.append(line)

out_lines.append('-- ============================================================\n')

with open(init_path, 'w', encoding='utf-8') as f:
    f.writelines(out_lines)

    # Append all chunks
    for i in range(1, 6):
        chunk_path = f'/Users/hieudevdut/Library/CloudStorage/GoogleDrive-hieudevnguyen.work@gmail.com/My Drive/Projects/SQL-Executor/backend/sql/append_{i}.sql'
        with open(chunk_path, 'r', encoding='utf-8') as chunk_f:
            f.write(chunk_f.read())
            f.write('\n')
        # Clean up
        os.remove(chunk_path)

print("init.sql updated successfully.")
