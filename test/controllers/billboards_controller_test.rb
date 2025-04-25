require "test_helper"

class BillboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @billboard = billboards(:one)
  end

  test "should get index" do
    get billboards_url
    assert_response :success
  end

  test "should get new" do
    get new_billboard_url
    assert_response :success
  end

  test "should create billboard" do
    assert_difference("Billboard.count") do
      post billboards_url, params: { billboard: { active: @billboard.active, content: @billboard.content } }
    end

    assert_redirected_to billboard_url(Billboard.last)
  end

  test "should show billboard" do
    get billboard_url(@billboard)
    assert_response :success
  end

  test "should get edit" do
    get edit_billboard_url(@billboard)
    assert_response :success
  end

  test "should update billboard" do
    patch billboard_url(@billboard), params: { billboard: { active: @billboard.active, content: @billboard.content } }
    assert_redirected_to billboard_url(@billboard)
  end

  test "should destroy billboard" do
    assert_difference("Billboard.count", -1) do
      delete billboard_url(@billboard)
    end

    assert_redirected_to billboards_url
  end
end
