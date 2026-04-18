class LicensePlate:
    # should include stuff from database: state, plate_title, source_img
    pass

class Tree:
    # write tree data structure here
    def to_json():
        # should output the tree as a .json file
        # this is what the app will take as input
        pass
    pass

# Good license plate database
url = "https://raw.githubusercontent.com/jonkeegan/us-license-plates/refs/heads/main/us-license-plates.csv"

def scrape_license_plates():
    # Write a function that scrapes the license plates from the above url and adds them to the tree one by one
    # For example, all Pennsylvania license plates will belong to the same parent node
    pass