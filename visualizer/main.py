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
            "dark_yellow_1": [241, 194, 50],
            "dark_green_1": [106, 168, 79],
            "dark_cornflower_blue 1": [60, 120, 216],
            "dark_red_1": [204, 0, 0],
            'dark_purple_1': [103, 78, 167],
            'dark_magenta_1': [166, 77, 121],
            'dark_cyan_1': [69, 129, 142],
            'dark_orange_1': [230, 145, 56],
        }

        self.d_c_dict = {
            "dark_yellow_3": [127, 96, 0],
            "dark_green_3": [39, 78, 19],
            "dark_cornflower_blue 3": [28, 69, 135],
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
        self.row_index = 2

    #in a simulation
        self.arbiter_list_id = []
        self.consumer_list_id = []
        self.arbiter_count = 1
        self.consumer_count = 1
        self.d_color_count = 0
        self.l_color_count = 0

    def simulation_renderer(self):
        for sim in self.sims:
            SheetRenderer.reset_variables(self)
            SheetRenderer.info_renderer(self, sim)
            for i in range(0, len(sim)):
                if isinstance(sim[i], ArbiterDataPoint):
                    SheetRenderer.type_append_arb(self, sim[i])
                    #SheetRenderer.color_arb_blocks(self, sim[i])
                elif isinstance(sim[i], ConsumerDataPoint):
                    SheetRenderer.type_append_con(self, sim[i])
                    SheetRenderer.color_con_blocks(self, sim[i])
            self.row_index += 4

    #reset all the variables to initial position for each new simulation

    def reset_variables(self):
        self.arbiter_list_id = []
        self.consumer_list_id = []
        self.arbiter_count = 1
        self.consumer_count = 1
        self.d_color_count = 0
        self.l_color_count = 0

    #go through each line, define the type and append to a list of con/arb

    def type_append_arb(self, line):
        if line.arbiter_id not in self.arbiter_list_id:
            self.requests.append(input_data_into_cell((self.row_index), 0, "Arbiter" + str(self.arbiter_count)))
            self.arbiter_list_id.append(line.arbiter_id)
            self.arbiter_count += 1
            self.row_index += 1

    def type_append_con(self, line):
        if line.consumer_id not in self.consumer_list_id:
            self.requests.append(input_data_into_cell((self.row_index), 0, "Consumer" + str(self.consumer_count)))
            self.consumer_list_id.append(line.consumer_id)
            self.consumer_count += 1
            SheetRenderer.color_append_con(self, line)
            self.row_index += 1

    #append a color to each con

    def color_append_con(self, line):
        line.light_colors = list(self.l_c_dict.keys())[self.l_color_count]
        line.dark_colors = list(self.d_c_dict.keys())[self.d_color_count]
        self.d_color_count += 1
        self.l_color_count += 1

    #make a loop that will color in each block depending on the line

    def color_con_blocks(self, line):
        column = int(line.cycle_number) + 1
        if line.operation == 'io':
            print(line.operation)
            color = line.light_colors
            print(color)
            self.requests.append(update_cell_color(self.l_c_dict[color][0], self.l_c_dict[color][1], self.l_c_dict[color][2], self.row_index, self.row_index + 1, column, column + 1))
        elif line.operation == 'work':
            print(line.operation)
            color = line.dark_colors
            print(color)
            self.requests.append(update_cell_color(self.d_c_dict[color][0], self.d_c_dict[color][1], self.d_c_dict[color][2], self.row_index, self.row_index + 1, column, column + 1))


    def main_details_renderer(self):
        self.requests.append(get_clean_sheet_request())
        self.requests.append(unmerge_cells())
        self.requests.append(create_name_to_sheet("Generator"))

    def info_renderer(self, sim):
        self.offset_row += self.offset_row_add
        self.requests.append(input_data_into_cell_merged(self.offset_row, self.offset_row + 1, 1, 25))
        self.requests.append(input_data_into_cell(self.offset_row + 1, 1, "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18"))
        self.offset_row_add = len(sim) + 4

    def render_sheet(self):
        SheetRenderer.main_details_renderer(self)
        SheetRenderer.simulation_renderer(self)

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
        self.consumer_id = ConsumerId(consumer_id)
        self.operation = operation
        self.cycle_number = cycle_number

class ConsumerId():

    def __init__(self, consumer_id):
        self.consumer_id = consumer_id
        self.dark_colors = None
        self.light_colors = None

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

def input_clock_data():
    None

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