# Talos SDK 
> Get up and running with the Talos cloud


## Install

You'll need python, virtualenv, and make installed.  From there you can run the following to get a jupyter notebook up and running and follow along with the rest of this tour.  This was tested on python 3.8.

```bash
git clone https://github.com/talosiot/talosSDK.git
cd talosSDK
make env
make server
```

This makes the Jupyter notebook server available.  Open up a browser to connect to it.  Usually the address is similar to `http://127.0.0.1:8888/lab?token=<some long string>`.  Once the Jupyter notebook is up, open `index.ipynb` on the left panel.  You can then follow along and run all this code yourself (<kbd>Ctrl</kbd>+<kbd>ENTER</kbd> to execute a cell).  If you are doing this in a virtual machine, use the ip address of the virtual machine.  By default, the port is `8888`.

## General Organization

Starting from the highest level of organization, let's define a few terms:

- An Organization is a collection of one or more Owners. 
- An Owner is a company that is responsible for real estate.
- An Address represents a single street address or building.  An Address may have many Locations or Equipment within it.
- A Location represents a place within an Address such as a rooftop, the second floor, or the basement.  A Location may itself have many Locations or Equipment within it.

For example, Acme Group is an Organization.  It has two Owners, Beta Co. and Charlie Co.  Beta Co. owns a building (Address) at 123 Main St, which has Equipment on the first floor (Location) and the roof (Location).


## Guided Tour

Get the API key that you were provided and fill it in below.  Or, set it as the environment variable `TALOS_API_KEY`

```python
import os
import requests
```

```python
api_key = 'PASTE YOUR API KEY HERE'
api_key = os.environ.get("TALOS_API_KEY", api_key)
header = {"Authorization": "Bearer {}".format(api_key)}
```

Edit the URL variable below to be the URL of the Talos server.  

```python
URL = 'http://sandbox.talosiot.com'
api_url = URL+"/api/ale/v1"
```

Create an owner

```python
new_owner = {"name": "My example owner"}
resp = requests.post(api_url+"/owner", json=new_owner, headers=header)
```

```python
resp.json()
```




    {'created': True, 'eid': 'KYFFdbcXkNKrNqFoZkiPhv'}



The above line should say `{'created': True, 'eid': 'SomeStringHere'}`.  The eid is a unique identifier that you'll use to refer to that owner.  Everything (owners, addresses, equipment) all have a unique eid identifier.  For example, to get information about the owners later you can get a list of all your owner eids from the `/owners` endpoint

```python
all_owners_resp = requests.get(api_url+'/owners', headers=header)
all_owners_resp.json()
```




    ['KYFFdbcXkNKrNqFoZkiPhv']



Then get the information about an individual owner from the endpoint `/owner` (singular) and using the query string `eid={}`

```python
owner_eids = all_owners_resp.json()
try:
    owner_eid = owner_eids[0] #save the first of the owner eids
    owners_resp = requests.get(api_url+'/owner?eid={}'.format(owner_eid), headers=header)
    print(owners_resp.json())
except IndexError:
    print("No owners were found in the /owners request")
```

    {'eid': 'KYFFdbcXkNKrNqFoZkiPhv', 'grafana_org_id': 2, 'name': 'My example owner', 'type': 'owner'}


Using the owner's eid you can add Address, Location, and Equipment underneath that owner.  Start by creating an address.  Note you can also use a web UI to do everything below.

```python
new_address = dict(
     owner_eid=owner_eid,
     name="New address", 
     city='Richmond', 
     state='VA', 
     street="123 Main St.", 
     postcode="23058", 
     desc='An example of creating a new building')

new_address_resp = requests.post(api_url+'/address', headers=header, json=new_address)
```

```python
main123_eid = new_address_resp.json()['eid']
```

Its possible to look up these addresses later by the owner's eid.

```python
all_address_resp = requests.get(api_url+'/address?owner_eid={}'.format(owner_eid), headers=header)
all_address_resp.json()
```




    [{'city': 'Richmond',
      'desc': 'An example of creating a new building',
      'eid': 'eJFGVornV79WhBEfycnj9X',
      'equipment': [],
      'locations': [],
      'name': 'New address',
      'owner_eid': 'KYFFdbcXkNKrNqFoZkiPhv',
      'postcode': '23058',
      'state': 'VA',
      'street': '123 Main St.'}]



Or by the eid of the address.  
{% include note.html content='There is a known bug where this endpoint does not return the `owner_eid`' %}

```python
single_address_resp = requests.get(api_url+'/address?eid={}'.format(main123_eid), headers=header)
single_address_resp.json()
```




    [{'city': 'Richmond',
      'desc': 'An example of creating a new building',
      'eid': 'eJFGVornV79WhBEfycnj9X',
      'equipment': [],
      'locations': [],
      'name': 'New address',
      'owner_eid': None,
      'postcode': '23058',
      'state': 'VA',
      'street': '123 Main St.'}]



Add a Location at the Address by specifying the eid as the `parent_eid`.

```python
new_location = dict(
        name="123 Main - Rooftop",
        desc="The roof at 123 Main St.",
        parent_eid=main123_eid
        )

new_location_resp = requests.post(api_url+'/location', headers=header, json=new_location)
```

```python
main123_roof_eid = new_location_resp.json()['eid']
main123_roof_eid
```




    'eM7N6AprXRJ8qWcKhWHjAX'



Finally add a piece of Equipment at the Location.  Note you could have added the Equipment directly to the Address.  At present, we only support two equipment types: `Package` and `EmulatedHVAC`.

```python
new_equipment = dict(
    name='Fake HVAC 1',
    types=['EmulatedHVAC'], 
    make='Example', 
    model='Example Model', 
    serial='123', 
    lat=37.605360056227276,
    lng=-77.5610195200356,
    location_eid=main123_roof_eid,
    desc='Fake RTU')

new_equip_resp = requests.post(api_url+'/equipment', headers=header, json=new_equipment)
```

```python
new_equip_resp.json()
```




    {'created': True, 'eid': 'K3AyuWBoR3Dxh6hTjY2XRo'}



```python
new_equip_eid = new_equip_resp.json()['eid']
new_equip_eid
```




    'K3AyuWBoR3Dxh6hTjY2XRo'



Now that we've created some Locations and Equipment, let's make sure its all still there.  You can retrieve everything "downstream" of an Address or Location.

```python
downstream_resp = requests.get(api_url+'/location/downstream?eid={}'.format(main123_eid), headers=header)
```

```python
downstream_resp.json()
```




    {'equipment': [],
     'locations': [{'desc': 'The roof at 123 Main St.',
       'eid': 'eM7N6AprXRJ8qWcKhWHjAX',
       'equipment': [{'desc': '',
         'eid': 'K3AyuWBoR3Dxh6hTjY2XRo',
         'is_critical': False,
         'lat': 37.605360056227276,
         'lng': -77.5610195200356,
         'location_eid': 'eM7N6AprXRJ8qWcKhWHjAX',
         'make': 'Example',
         'model': 'Example Model',
         'name': 'Fake HVAC 1',
         'serial': '123',
         'type': 'equipment',
         'types': ['EmulatedHVAC']}],
       'locations': [],
       'name': '123 Main - Rooftop',
       'parent_eid': 'eJFGVornV79WhBEfycnj9X',
       'type': 'location'}]}



There it is!  The nested structure contains the Location, which itself contains the Equipment.

## Install a webhook

Lets install a webhook that will receive the alerts as they are fired.  A webhook will receive all alerts for all equipment "downstream" of it.  E.g., attaching a webhook to a single piece of equipment will give you all alerts for that equipment.  Attaching a webhook to a location gives you all alerts for all Equipment at that location (and any attached locations).

{% include note.html content='you must provide a url of a valid form' %}

```python
URL_OF_YOUR_WEBHOOK = 'http://172.30.200.1'  #put the url of your publically available endpoint here
PORT_OF_YOUR_WEBHOOK = 7222  #put your port number here

webhook = {'name': 'My webhook', 
           'url':'{}:{}'.format(URL_OF_YOUR_WEBHOOK, PORT_OF_YOUR_WEBHOOK), 
           'linked_eids':[main123_eid]
          }
create_webhook_resp = requests.post(api_url+'/webhook', json=webhook, headers=header)
#resp = requests.get(api_url+"/webhook?eid=abcd"+'/webhook')
print(create_webhook_resp.status_code)
print(create_webhook_resp.json())
```

    200
    {'eid': 'byt7mgVvDSaqkrEdogG8hZ', 'linked_eids': ['eJFGVornV79WhBEfycnj9X'], 'name': 'My webhook'}


```python
webhook_eid = create_webhook_resp.json()['eid']
```

Retrieve information about a webhook

```python
resp = requests.get(api_url+"/webhook?eid={}".format(webhook_eid), headers=header)
print(resp.status_code)
print(resp.json())
```

    200
    {'eid': 'byt7mgVvDSaqkrEdogG8hZ', 'linked_eids': ['eJFGVornV79WhBEfycnj9X'], 'name': 'My webhook'}


## Trigger an alarm

In normal operation, alarms trigger automatically from the data coming off the sensor, but here we'll want to test the alarms.  If this step is successful, your webhook will be a payload with a form like:

```json
{'status': 'alert', 
 'alert': {'status': 'firing', 
           'labels': {'alertname': 'OFM Malfunction', 'device_eid': 'LNr7azgRgLwtdVBDWS68N9', 'severity': 'critical'}, 
           'name': 'OFM Malfunction', 
           'annotations': {'summary': 'Outdoor Fan Motor did not come on with the compressor'}, 
           'summary': 'Outdoor Fan Motor did not come on with the compressor', 
           'fingerprint': '93a9986f-1f8b-4bcd-9835-b364a8fae699', 
           'device_eid': 'LNr7azgRgLwtdVBDWS68N9', 
           'severity': 'critical', 
           'incident': {'iid': 'XHFiNmUkRxOSsEynrmXjdw'}, 
           'iid': 'XHFiNmUkRxOSsEynrmXjdw'}, 
 'device': {'eid': 'LNr7azgRgLwtdVBDWS68N9', 
            'lng': -77.5610195200356, 
            'serial': '123', 
            'name': 'Fake HVAC 1', 
            'model': 'Example Model', 
            'make': 'Example', 
            'lat': 37.605360056227276, 
            'is_critical': false}}
```

{% include note.html content='if the recipient of your webhook is not ready to receive it, this step will fail and the test incident will not be created.' %}

```python
repairs_url = URL+'/api/repairs/v1'
resp = requests.post(repairs_url+'/',json={'alert_name': 'OFM_broken', 'eid': new_equip_eid, 'force_new': True})
print(resp.status_code)
print(resp.json())
```

    200
    {'iid': 'fdhrn52fQ4SAONpapf_yMA'}


```python
incident_id = resp.json()['iid']
```

Get the active alarms

```python
get_alarms_endpoint = repairs_url+'/{eid}/{condition}'.format(eid=new_equip_eid, condition='active')
print(get_alarms_endpoint)
resp = requests.get(get_alarms_endpoint)
print(resp.status_code)
print(resp.json())
```

    http://sandbox.talosiot.com/api/repairs/v1/K3AyuWBoR3Dxh6hTjY2XRo/active
    200
    ['fdhrn52fQ4SAONpapf_yMA']


Close the alarm with the incident_id

```python
resp = requests.post(repairs_url+'/close',json={'iid': incident_id})
print(resp.status_code, resp.json())
```

    200 [{'newevent': {'action': 'closed', 'ts': 1616766599}}]


Get a record of what has happened with this alarm

```python
events_endpoint = repairs_url+'/events?iid={}'.format(incident_id)
resp = requests.get(events_endpoint)
print(events_endpoint)
print(resp.status_code)
print(resp.json())
```

    http://sandbox.talosiot.com/api/repairs/v1/events?iid=fdhrn52fQ4SAONpapf_yMA
    200
    [{'action': 'started', 'ts': 1616693325}, {'action': 'closed', 'ts': 1616766599}]

