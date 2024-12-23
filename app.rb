# frozen_string_literal: true

require 'sinatra'
require_relative 'app/controllers/email_controller'

use EmailController
