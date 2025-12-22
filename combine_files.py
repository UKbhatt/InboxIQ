import os
from pathlib import Path

def combine_dart_files():
    base_path = Path("lib")
    output_file = Path("complete_feature_code.txt")
    
    folders = [
        base_path / "features" / "email",
        base_path / "core"
    ]
    
    with open(output_file, "w", encoding="utf-8") as out:
        for folder in folders:
            if not folder.exists():
                continue
            
            dart_files = sorted(folder.rglob("*.dart"))
            
            for dart_file in dart_files:
                relative_path = dart_file.relative_to(Path("lib"))
                out.write("=" * 80 + "\n")
                out.write(f"{relative_path}\n")
                out.write("=" * 80 + "\n\n")
                
                try:
                    with open(dart_file, "r", encoding="utf-8") as f:
                        content = f.read()
                        lines = content.split("\n")
                        for line in lines:
                            stripped = line.rstrip()
                            if not stripped.startswith("//"):
                                out.write(stripped + "\n")
                            elif stripped.strip() == "//":
                                out.write("\n")
                except Exception as e:
                    out.write(f"Error reading file: {e}\n")
                
                out.write("\n\n")

if __name__ == "__main__":
    combine_dart_files()
    print("Files combined successfully!")

