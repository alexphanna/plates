import csv  #imports the CSV module to read and process CSV data
import json  #allows the program to convert Python data into JSON format
import requests #allows the program to retrieve data from a URL
from io import StringIO #allows text to be used like a file


#LicensePlate class stores data for each plate
class LicensePlate:
    def __init__(self, state, plate_title, source_img):
        self.state = state       #stores the state for each license plate
        self.plate_title = plate_title #stores the plate title for each license plate
        self.source_img = source_img #stores the image URL for each license plate

#converts self into a dict so it can be used with JSON 
    def to_dict(self):
        return {
            "state": self.state,
            "plate_title": self.plate_title,
            "source_img": self.source_img
        }


#this represents each node in the tree
class TreeNode:
    def __init__(self, name):
        self.name = name  #assigns a name to each node
        self.children = [] #empty list to store child nodes
        self.plates = []    #empty list to store plates for each node

    def add_child(self, node):
        self.children.append(node) #adds a child node to the current node's children list

    def add_plate(self, plate): 
        self.plates.append(plate) #adds a license plate to the current node's plates list
        
#converts tree node and all its nested children and plates into a dict
    def to_dict(self):
        return {
            "name": self.name,
            "plates": [p.to_dict() for p in self.plates],
            "children": [child.to_dict() for child in self.children]
        }


#this manages the entire tree structure
class Tree:
    def __init__(self):
        self.root = TreeNode("License Plates") #creates the root node

    def add_path(self, path):
        current = self.root #starts at the root

        for part in path:
            found = None

            #check if node already exists
            for child in current.children:
                if child.name == part:
                    found = child
                    break

            #if not found create it
            if not found:
                found = TreeNode(part)
                current.add_child(found)

            #move to next level
            current = found

        return current 

    def to_json(self, filename="plates.json"):
        with open(filename, "w") as f:  #opens the file for writing
            json.dump(self.root.to_dict(), f, indent=4)  #writes the tree as JSON



url = "https://raw.githubusercontent.com/jonkeegan/us-license-plates/refs/heads/main/us-license-plates.csv"


#main function to scrape and build the tree
def scrape_license_plates():
    tree = Tree()  #create tree

    response = requests.get(url)  #download CSV
    data = StringIO(response.text) #make text readable like a file
    reader = csv.DictReader(data) #read CSV as dictionaries
    
#grabs the state title and image URL from each row in the CSV 
    for row in reader:
        state = row.get("state")
        title = row.get("plate_title")
        img = row.get("source_img")

        plate = LicensePlate(state, title, img) #create plate object

        node = tree.add_path(["United States", state]) #create/find state node
        node.add_plate(plate) #add plate to that node

    tree.to_json() #save to JSON file

    return tree



if __name__ == "__main__":
    scrape_license_plates()
