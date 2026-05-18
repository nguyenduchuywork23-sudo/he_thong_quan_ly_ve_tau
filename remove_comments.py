import os

def should_exclude_dir(dir_path):
    exclusions = {
        'bin', 'obj', 'Migrations', '.vs', 
        'build', '.dart_tool', '.git', '.idea', 
        'windows', 'linux', 'macos', 'web', 'android', 'ios'
    }
    parts = os.path.normpath(dir_path).split(os.sep)
    for part in parts:
        if part in exclusions:
            return True
    return False

def should_exclude_file(file_name):
    if not (file_name.endswith('.cs') or file_name.endswith('.dart')):
        return True
    
    if file_name.endswith('.g.dart') or file_name.endswith('.freezed.dart') or file_name.endswith('.Designer.cs'):
        return True
        
    return False

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    new_lines = []
    for line in lines:
        stripped = line.lstrip()
        # Nếu dòng bắt đầu bằng // (bao gồm cả ///) thì bỏ qua hoàn toàn
        if stripped.startswith('//'):
            continue
        new_lines.append(line)
        
    # Chỉ ghi lại nếu có sự thay đổi (tức là có dòng bị xóa)
    if len(lines) != len(new_lines):
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)

def main():
    root_dir = r'c:\Users\Asus\he_thong_quan_ly_ve_tau'
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Lọc bỏ các thư mục không cần quét
        dirnames[:] = [d for d in dirnames if not should_exclude_dir(os.path.join(dirpath, d))]
        
        for filename in filenames:
            if not should_exclude_file(filename):
                file_path = os.path.join(dirpath, filename)
                try:
                    process_file(file_path)
                except Exception as e:
                    print(f'Lỗi khi xử lý file {file_path}: {e}')
    
    print("Hoàn tất việc xóa comment!")

if __name__ == '__main__':
    main()
