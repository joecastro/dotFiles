import json
from pathlib import Path

def main():
    with open('profile_template.json') as t_file:
        template_data = json.load(t_file)

    with open('profile_substitutions.json') as s_file:
        sub_data = json.load(s_file)

    for sub in sub_data:
       profile_name = sub['Name']
       bg_location = Path(sub['Background Image Location']).absolute()
       profile = template_data | sub
       profile['Background Image Location'] = str(bg_location)

       with open(profile_name + ".json", 'w') as outfile:
          json.dump(profile, outfile, indent=2, sort_keys=True)

    t_file.close()
    s_file.close()

if __name__ == "__main__":
    main()
