import datetime
import json
import sys

import frappe
from frappe.utils.install import complete_setup_wizard
from frappe.desk.page.setup_wizard.setup_wizard import make_records

params = json.loads(sys.argv[1])

print('Setup Wizard')
complete_setup_wizard()

now = datetime.datetime.now()
year = now.year

fy = frappe.get_doc(
    {
        "doctype": "Fiscal Year",
        "year": params["fiscal_year"],
        "year_end_date": params["year_end_date"],
        "year_start_date": params["year_start_date"],
    }
)
try:
    fy.save()
except:
    pass

def get_company_record():
    return {
      "doctype": "Company",
      "company_name": params["company_name"],
      "default_currency": params["default_currency"],
      "country": params["country"],
      "abbr": params["abbr"]
    }

def get_primary_user_record():
    return {
        'doctype': 'User',
        'email': params["email"],
        'first_name': params["first_name"],
        'new_password': params["new_password"],
        'user_type': 'System User',
        "roles": [
            {
            "docstatus": 0,
            "doctype": "Has Role",
            "parent": params["email"],
            "parentfield": "roles",
            "parenttype": "User",
            "role": "System Manager"
            }
        ]
    }

def fetch_records():
    json_file = '/tmp/records.json'
    records = json.loads(open(json_file).read())

    records.insert(0, get_primary_user_record())
    records.insert(0, get_company_record())
    return records

def create_records(records):
    for record in records:
        print(f"Processing {record['doctype']}")

        frappe.db.commit()
        try:
            if record.get('name'):
                exists = frappe.db.exists(record['doctype'], record['name'])
            else:
                _record = {}
                for key, value in record.items():
                    if not isinstance(value, str):
                        continue
                    _record[key] = value

                exists = frappe.db.exists(_record)

            if not exists:
                print(f"{record['doctype']}     Creating")
                print(record)
                make_records([record])
                frappe.db.commit()
            else:
                print(f"{record['doctype']}     Exists")
        except ImportError as e:
            frappe.db.rollback()
            print('Failed ' + record['doctype'])
            print(str(e))

records = fetch_records()
create_records(records)

# finish onboarding
modules = frappe.get_all('Module Onboarding', fields=['name'])
for module in modules:
    module_doc = frappe.get_doc('Module Onboarding', module.name)
    if not module_doc.check_completion():
        steps = module_doc.get_steps()
        for step in steps:
            step.is_complete = True
            step.save()


# set password for all users
frappe.flags.in_test = True

#users = frappe.get_all('User', pluck='name')
#for user in users:
#    user = frappe.get_doc('User', user)
#    user.new_password = 'p'
#    user.save()

# settings
#hr_settings = frappe.get_doc("HR Settings")
#hr_settings.standard_working_hours = 2
#hr_settings.save()

# holiday_list = frappe.get_doc('Holiday List', 'weekends')
#company = frappe.get_doc('Company', 'AvilPage')
#company.default_holiday_list = holiday_list.name
#company.default_currency = "INR"
#company.save()


frappe.db.commit()