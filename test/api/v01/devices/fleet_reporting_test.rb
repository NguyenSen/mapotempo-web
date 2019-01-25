# Copyright Â© Mapotempo, 2017
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
require 'test_helper'

class V01::Devices::FleetReportingTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  require Rails.root.join('test/lib/devices/api_base')
  include ApiBase

  require Rails.root.join('test/lib/devices/fleet_base')
  include FleetBase

  setup do
    @customer = customers(:customer_one)
    @customer.update(devices: { fleet: { enable: true, user: 'driver1', api_key: '123456' } }, enable_vehicle_position: true, enable_stop_status: true)
    set_route
  end

  test 'should get reporting' do
    stub_request(:get, "http://localhost:8084/api/0.1/reportings?format=json&from=2019-01-01&to=2019-02-01&with_actions=true")
    .with(
      headers: {
      'Authorization'=>'Token token=123456',
      'Charset'=>'utf-8',
      'Content-Type'=>'application/json'
      })
    .to_return(status: 200, body: "", headers: {})


    get api('devices/fleet/reporting', { customer_id: @customer.id, begin_date: '01-01-2019', end_date: '31-01-2019', with_actions: true })
    assert_equal 200, last_response.status
  end

end
