import os
import zipfile

def zipdir(path, ziph):
    # ziph is zipfile handle
    for root, dirs, files in os.walk(path):
        # Filter out directories
        dirs[:] = [d for d in dirs if d not in ['node_modules', '.git', '.expo', 'dist', '__pycache__', '.cache', '.modcache', '.tools']]
        
        for file in files:
            if file == 'quiz_master_backup_zip.zip' or file.endswith('.tar.gz') or file.endswith('.zip') or file.startswith('.'):
                 continue
            
            file_path = os.path.join(root, file)
            arcname = os.path.relpath(file_path, os.path.join(path, '..'))
            
            # Additional check to ensure we aren't adding files from excluded dirs if walk somehow got there
            if 'node_modules' in file_path or '.git' in file_path:
                continue
                
            print(f"Adding {file_path}")
            ziph.write(file_path, arcname)

if __name__ == '__main__':
    with zipfile.ZipFile('quiz_master_backup.zip', 'w', zipfile.ZIP_DEFLATED) as zipf:
        zipdir('.', zipf)
    print("Zip created successfully.")
