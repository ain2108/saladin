from __future__ import print_function
import pickle
import os.path

from googleapiclient import discovery
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request

# If modifying these scopes, delete the file token.pickle.
SCOPES = ['https://www.googleapis.com/auth/drive']

# The ID and range of a sample spreadsheet.
SAMPLE_SPREADSHEET_ID = '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms'
SAMPLE_RANGE_NAME = 'Class Data!A2:E'

def create_name_to_sheet(title):
    return {
        "addSheet": {
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
            "fields": "userEnteredValue"
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

def update_cell_color():
    return {
        "updateCells": {
            "rows": [{
                "values": [{
                    "userEnteredFormat": {
                        "backgroundColor": {
                                "red": 1,
                                "green": 0,
                                "blue": 0,
                                "alpha": 1
                                }
                            }
                        }]
                    }],
            "fields": 'userEnteredFormat.backgroundColor',
            "range": {
                "sheetId": 0,
                "startRowIndex": 0,
                "endRowIndex": 1,
                "startColumnIndex": 0,
                "endColumnIndex": 1
            }
        }
    }

def main():
    """Shows basic usage of the Sheets API.
    Prints values from a sample spreadsheet.
    """
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

    requests = []

    # Clean exiting sheet
    requests.append(get_clean_sheet_request())
    requests.append(input_data_into_cell(0,0,"This is it, bebs"))
    requests.append(update_cell_color())


    spreadsheet_body = {
        'requests': requests
    }
    #sheet = service.spreadsheets().create().execute()
    #1OMMaFubnCFiFJjl0NZYHkq5bSNoFI6aHCRaP3XPsewY #the one after create

    #sheet = service.spreadsheets().get(spreadsheetId='1OMMaFubnCFiFJjl0NZYHkq5bSNoFI6aHCRaP3XPsewY')

    #print(sheet)

    #spreadsheetId = sheet['spreadsheetId']
    spreadsheetId = "1OMMaFubnCFiFJjl0NZYHkq5bSNoFI6aHCRaP3XPsewY"


    response = service.spreadsheets().batchUpdate(spreadsheetId=spreadsheetId,body=spreadsheet_body).execute()
    print(response)


    link = get(spreadsheetId)
    print(link)

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