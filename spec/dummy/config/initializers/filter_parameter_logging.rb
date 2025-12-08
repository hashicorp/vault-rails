# Copyright IBM Corp. 2015, 2025
# SPDX-License-Identifier: MPL-2.0

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password]
