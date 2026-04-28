import csv  # imports the CSV module to read and process CSV data
import requests # allows the program to retrieve data from a URL
from io import StringIO # allows text to be used like a file
from models import Tree, LicensePlate
from state_names import stateNames

import sys
from pathlib import Path

if len(sys.argv) < 2:
    raise SystemExit("Usage: generate_data.py <output_path>")

output_path = Path(sys.argv[1])
output_path.parent.mkdir(parents=True, exist_ok=True)


URL = "https://raw.githubusercontent.com/jonkeegan/us-license-plates/refs/heads/main/us-license-plates.csv"

# main function to scrape and build the tree
def scrape_license_plates():
    tree = Tree()  #create tree

    response = requests.get(URL)  #download CSV
    data = StringIO(response.text) #make text readable like a file
    reader = csv.DictReader(data) #read CSV as dictionaries
    
    # grabs the state title and image URL from each row in the CSV 
    for row in reader:
        state = stateNames[row.get("state")]
        title = row.get("plate_title")
        img = row.get("source_img")

        plate = LicensePlate(state, title, img) # create plate object

        node = tree.add_path(["United States", state]) # create/find state node
        node.add_plate(plate) # add plate to that node

    tree.to_json(output_path) # save to JSON file

    return tree

if __name__ == "__main__":
    scrape_license_plates()
