import yaml
import os
import sys

def verify_quiz(file_path):
    print(f"Checking {file_path}...")
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        
        if not data:
            print(f"  Error: File is empty.")
            return False
            
        if 'quiz' in data and isinstance(data['quiz'], dict):
            questions = data['quiz'].get('questions', [])
        elif 'questions' in data:
            questions = data['questions']
        elif isinstance(data, list):
            questions = data
        else:
            print(f"  Error: Could not find questions list.")
            return False
        
        errors = 0
        for i, q in enumerate(questions):
            q_id = q.get('id', f'unknown_{i}')
            options = q.get('options', [])
            
            # Check for valid number of options (2 to 6)
            if len(options) < 2 or len(options) > 6:
                print(f"  Error in {q_id}: Expected 2-6 options, found {len(options)}.")
                errors += 1
            
            # Check for unique options
            try:
                if len(set(options)) != len(options):
                    print(f"  Error in {q_id}: Options are not unique.")
                    errors += 1
            except TypeError:
                print(f"  Error in {q_id}: Options contain unhashable types (dicts?). options={options}")
                errors += 1
            
            # Check for valid answer index
            answer = q.get('correct_answer')
            if answer is None:
                # Fallback to 'answer' if present
                answer = q.get('answer')
                
            if answer is None or not isinstance(answer, int) or answer < 0 or answer >= len(options):
                print(f"  Error in {q_id}: Invalid answer index {answer}.")
                errors += 1
            
            # Check for explanation
            if not q.get('explanation'):
                print(f"  Error in {q_id}: Missing explanation.")
                errors += 1
        
        if errors == 0:
            print(f"  Success: All {len(questions)} questions in {file_path} are valid.")
            return True
        else:
            print(f"  Failed: {errors} errors found in {file_path}.")
            return False
            
    except Exception as e:
        print(f"  Error parsing YAML: {e}")
        return False

def main():
    files = []
    for root, dirs, filenames in os.walk("quizzes"):
        for filename in filenames:
            if filename.endswith(".yaml") or filename.endswith(".yml"):
                files.append(os.path.join(root, filename))
    
    all_valid = True
    for f in files:
        if not verify_quiz(f):
            all_valid = False
            
    if all_valid:
        print("\nAll quizzes passed validation!")
        sys.exit(0)
    else:
        print("\nSome quizzes failed validation.")
        sys.exit(1)

if __name__ == "__main__":
    main()
