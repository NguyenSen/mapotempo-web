require 'test_helper'

class DeliverablesByVehiclesControllerTest < ActionController::TestCase

  setup do
    @request.env['reseller'] = resellers(:reseller_one)
    @vehicle = vehicles(:vehicle_one)
    sign_in users(:user_one)
  end

  test 'should show deliverables by vehicle' do
    get :show, vehicle_id: @vehicle.id, planning_ids: @vehicle.customer.plannings.collect(&:id).join(',')
    assert_response :success
    assert_valid response
  end

end
