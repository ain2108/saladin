from __future__ import print_function
import pickle
import os.path

from googleapiclient import discovery
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request

# If modifying these scopes, delete the file token.pickle.
SCOPES = ['https://www.googleapis.com/auth/drive']

class DataPoint:
    pass

class Parser:

    def __init__(self, file_path, begin, end):
        simulations = []
        with open(file_path) as f:
            for line in f:
                # found start of section so start iterating from next line
                if line.startswith(begin):
                    simulation = []
                    for line in f:
                        # found end so end function
                        if line.startswith(end):
                            simulations.append(simulation)
                            break
                        dp = self.string_to_datapoint(line)
                        # yield every line in the section
                        simulation.append(dp)
        self.sims = simulations

    def string_to_datapoint(self, line) -> DataPoint:

        tokens = line.split(',')
        type = tokens[0]
        dp_params = tokens[1:]

        if type == 'a':
            return ArbiterDataPoint(arbiter_id=dp_params[0], consumer_id=dp_params[1], cycle_number=dp_params[2])
        elif type == 'c':
            return ConsumerDataPoint(consumer_id=dp_params[0], operation=dp_params[1], cycle_number=dp_params[2])

class SheetRenderer:

    def __init__(self, service, sims):
        self.l_c_dict = {
            "dark_yellow_1": (241, 194, 50),
            "dark_green_1": (106, 168, 79),
            "dark_cornflower_blue 1": (60, 120, 216),
            "dark_red_1": (204, 0, 0),
            'dark_purple_1': [103, 78, 167],
            'dark_magenta_1': [166, 77, 121],
            'dark_cyan_1': [69, 129, 142],
            'dark_orange_1': [230, 145, 56],
        }

        self.d_c_dict = {
            "dark_yellow_3": (127, 96, 0),
            "dark_green_3": (39, 78, 19),
            "dark_cornflower_blue 3": (28, 69, 135),
            'dark_red_3': [102, 0, 0],
            'dark_purple_3': [32, 18, 77],
            'dark_magenta_3': [76, 17, 48],
            'dark_cyan_3': [12, 52, 61],
            'dark_orange_3': [120, 63, 4]
        }

        self.dict = {
            "dark_yellow_1": [241, 194, 50],
            "dark_green_1": [106, 168, 79],
            "dark_cornflower_blue 1": [60, 120, 216],
            "dark_red_1": [204, 0, 0],
            'dark_purple_1': [103, 78, 167],
            'dark_magenta_1': [166, 77, 121],
            'dark_cyan_1': [69, 129, 142],
            'dark_orange_1': [230, 145, 56],
            "dark_yellow_3": (127, 96, 0),
            "dark_green_3": (39, 78, 19),
            "dark_cornflower_blue 3": (28, 69, 135),
            'dark_red_3': (102, 0, 0),
            'dark_purple_3': (32, 18, 77),
            'dark_magenta_3': (76, 17, 48),
            'dark_cyan_3': (12, 52, 61),
            'dark_orange_3': (120, 63, 4)
        }

        self.extra_light_colors = {
            "light_yellow_1": (255, 217, 102),
            "light_green_1": (147, 196, 125),
            "light_yellow_3": (255, 242, 204),
            "light_green_3": (217, 234, 211),
        }

        self.requests = []
        self.service = service
        self.sims = sims
        self.offset_row = 0
        self.offset_row_add = 0


    # find and register all unique arbiters

    def assign_arbiter(self, sim):

        arbiters = {}
        count = 0

        for dp in sim:
            if isinstance(dp, ArbiterDataPoint) and dp.arbiter_id in arbiters:

                arbiters[dp.arbiter_id] = (dp.arbiter_id, count)
                count += 1

        self.create_var_arb(arbiters)
        return arbiters

    #find and register all consumers and assign a color to each unique one

    def assign_colors_to_consumers(self, sim, arbiters):

        ctcr = {}
        count = 0

        l_colors = list(self.l_c_dict.keys())
        d_colors = list(self.d_c_dict.keys())

        for dp in sim:
            if isinstance(dp, ConsumerDataPoint) and dp.consumer_id not in ctcr:

                l_color = l_colors[count]
                d_color = d_colors[count]
                ctcr[dp.consumer_id] = (l_color, d_color, count)

                count += 1

        self.create_var_con(ctcr)

        return ctcr

    #print the arb variables
    #in order to do so, require to have an updated self.offset_row

    def create_var_arb(self, arbiters):
        row = 0 + self.offset_row
        for arb in arbiters:
            self.requests.append(input_data_into_cell(row, 0, "Arbiter"))
            row += 1
            self.offset_row += 1

    #print the arb variables
    #in order to do so, require to have an updated self.offset_row

    def create_var_con(self, ctcr):
        row = 0 + self.offset_row
        for con in ctcr:
            self.requests.append(input_data_into_cell(row, 0, "Consumer"))
            row += 1
            self.offset_row += 1

    #get ready the info and the updated self.offset_row

    def info_renderer(self):
        self.requests.append(input_data_into_cell_merged(self.offset_row, self.offset_row + 1, 1, 25))
        self.requests.append(input_data_into_cell(self.offset_row + 1, 1, "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18"))

    #how the process for each simulation looks like

    def render_simulation(self, sim):

        self.info_renderer()

        #self.base_consumer_row = self.offset_row + 1 + len(arbiters) + 1


        arbiters = self.assign_arbiter(sim)
        ctcr = self.assign_colors_to_consumers(sim, arbiters)

        for dp in sim:

            #color arbiters
            #order consumer based on arbiters

            self.color_con_blocks(dp, ctcr)

    #make a loop that will color in each block depending on the line

    def color_con_blocks(self, dp, ctcr):

        if isinstance(dp, ConsumerDataPoint):

            # get the color of a id from the ctcr list
            values = ctcr.get(dp.consumer_id)
            light_color = values[1]
            dark_color = values[0]
            column = int(dp.cycle_number) + 1

            if dp.operation == 'io':

                #color in the block
                light_color = self.d_c_dict.get(light_color)
                self.requests.append(update_cell_color(light_color[0], light_color[1], light_color[2], values[2], values[2] + 1, int(column), int(column) + 1))

            elif dp.operation == 'work':

                dark_color = self.l_c_dict.get(dark_color)
                self.requests.append(update_cell_color(dark_color[0], dark_color[1], dark_color[2], values[2], values[2] + 1, int(column), int(column) + 1))

    #first step in creating the spreadsheet

    def main_details_renderer(self):
        self.requests.append(get_clean_sheet_request())
        self.requests.append(unmerge_cells())
        self.requests.append(create_name_to_sheet("Generator"))

    # process through the whole data /each sim rendering/ file and produce the info+blocks

    def simulations_renderer(self):
        for sim in self.sims:
            self.render_simulation(sim)

    def render_sheet(self):
        self.main_details_renderer()
        self.simulations_renderer()

        spreadsheet_body = {
            'requests': self.requests
        }
        # sheet = service.spreadsheets().create().execute()
        #create a new spreadsheet

        spreadsheetId = "1OMMaFubnCFiFJjl0NZYHkq5bSNoFI6aHCRaP3XPsewY"
        self.service.spreadsheets().batchUpdate(spreadsheetId=spreadsheetId, body=spreadsheet_body).execute()

        request_link = self.service.spreadsheets().get(spreadsheetId=spreadsheetId).execute()
        print(request_link)

class ArbiterDataPoint(DataPoint):

    def __init__(self, arbiter_id, consumer_id, cycle_number):
        self.arbiter_id = arbiter_id
        self.consumer_id = consumer_id
        self.cycle_number = cycle_number


class ConsumerDataPoint(DataPoint):

    def __init__(self, consumer_id, operation, cycle_number):
        self.consumer_id = consumer_id
        self.operation = operation
        self.cycle_number = cycle_number


def create_name_to_sheet(title):
    return {
        "updateSpreadsheetProperties": {
            "fields": "title",
            "properties": {
                "title": title,
                }
            }
        }

def get_clean_sheet_request():
    return {
        "updateCells": {
            "range": {
                "sheetId": 0
                },
            "fields": "*", #userEnteredValue
            }
        }

def unmerge_cells():
    return {
        'unmergeCells':{
                'range': {
                "sheetId": 0
                    }
                }
            }

def input_data_into_cell(rowIndex, columnIndex, data):
    return {
        'pasteData': {
            "coordinate": {
                "rowIndex": rowIndex,
                "columnIndex": columnIndex,
                "sheetId": 0,
            },
            #"type": "A String",  # How the data should be pasted.
            "delimiter": ",",  # The delimiter in the data.
            #"html": False,  # True if the data is HTML.
            "data": data,  # The data to insert.
            }
        }


def update_cell_color(red, green, blue, startRowIndex, endRowIndex, startColumnIndex,endColumnIndex):
    return {
        "updateCells": {
            "rows": [{
                "values": [{
                    "userEnteredFormat": {
                        "backgroundColor": {
                                "red": red,
                                "green": green,
                                "blue": blue,
                                "alpha": 1,
                                }
                            }
                        }]
                    }],
            "fields": '*',
            "range": {
                "sheetId": 0,
                "startRowIndex": startRowIndex,
                "endRowIndex": endRowIndex,
                "startColumnIndex": startColumnIndex,
                "endColumnIndex": endColumnIndex
            }
        }
    }

def input_data_into_cell_merged(startRowIndex, endRowIndex, startColumnIndex, endColumnIndex):
    return {
      "mergeCells": {
        "range": {
          "sheetId": 0,
          "startRowIndex": startRowIndex,
          "endRowIndex": endRowIndex,
          "startColumnIndex": startColumnIndex,
          "endColumnIndex": endColumnIndex
        },
        "mergeType": "MERGE_ALL"
      }
    }


def main():
    creds = None
    # The file token.pickle stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        # Save the credentials for the next run
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)
    service = discovery.build('sheets', 'v4', credentials=creds)

    p =  Parser('data', '=====SIM', '=====SIM-END')
    result = SheetRenderer(service, p.sims)
    result.render_sheet()


    '''
    # Call the Sheets API
    sheet = service.spreadsheets()
    result = sheet.values().get(spreadsheetId=SAMPLE_SPREADSHEET_ID,
                                range=SAMPLE_RANGE_NAME).execute()

    values = result.get('values', [])

    if not values:
        print('No data found.')
    else:
        print('Name, Major:')
        for row in values:
            # Print columns A and E, which correspond to indices 0 and 4.
            print('%s, %s' % (row[0], row[4]))
    '''

if __name__ == '__main__':
     main()