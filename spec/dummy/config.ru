# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run Rails.application
