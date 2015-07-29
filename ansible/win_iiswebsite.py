#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: win_iissite
version_added: "0.1"
short_description: Adds and removes Windows IIS Site
description:
     - Installs or uninstalls Windows IIS Site
options:
  name:
    description:
      - Name of IIS Site
    required: true
    default: null
    aliases: []
  state:
    description:
      - State of the IIS Sites on the system
    required: false
    choices: 
      - present
      - absent
    default: present
    aliases: []
  physicalpath:
    description:
      - Physical Path of the IIS Site
    required: true
    choices:
      - valid path
    default: null
    aliases: []
  bindings:
    description:
      - Sets bindings of the IIS Site
    required: false
    choices:
      - valid list with protocol and bindingInformation
    default: http *:80:*
    aliases: []
author: Brian Ott
'''

EXAMPLES = '''
# This creates IIS Site.

# Playbook example
---
- name: Create Test Website
  hosts: all
  gather_facts: false
  tasks:
    - name: New Test Website
      win_iissite:
        name: "TestWebsite"
        state: present
        physicalpath: "c:\\TestWebsite"
        bindings:
        -
         protocol: "http"
         bindingInformation: "*:80:www.mytestsite.com"
        -
         protocol: "http"
         bindingInformation: "*:80:mytestsite.com"
'''
