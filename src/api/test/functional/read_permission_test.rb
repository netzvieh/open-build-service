require File.dirname(__FILE__) + '/../test_helper'
require 'source_controller'

class ReadPermissionTest < ActionController::IntegrationTest 

  fixtures :all
  
  def test_basic_read_tests
    ActionController::IntegrationTest::reset_auth 
    prepare_request_with_user "tom", "thunder"
    get "/source"
    assert_response :success
    # Do we want a check if the project is visible here ?

    # Access as a maintainer to a hidden project
# FIXME: a maintainer should always able to have read access, a write-only access makes no sense, does it ?
#    do_read_access_all_pathes( "adrian", :success )
# FIXME: file read access seems not to be possible atm
#    do_read_access_all_pathes( "adrian_reader", :success )
# FIXME: it looks like access is always possible atm
#    do_read_access_all_pathes( "adrian_downloader", 403 )
#    do_read_access_all_pathes( "adrian_nobody", 403 )
  end

  def do_read_access_all_pathes(user, response)
    ActionController::IntegrationTest::reset_auth 
    prepare_request_with_user user, "so_alone" #adrian users have all the same password

    get "/source/HiddenProject/_meta"
    # comment out for debugging:
#    print @response.body
    assert_response response
    get "/source/HiddenProject"
    assert_response response
    get "/source/HiddenProject/pack"
    assert_response response
    get "/source/HiddenProject/pack/_meta"
    assert_response response
    get "/source/HiddenProject/pack/my_file"
    assert_response response

  end
  protected :do_read_access_all_pathes

  # FIXME: to be implemented:
  # For source access:
  # * test operations on a project or package
  # * test package link creation
  # * test project link creation
  # * test creation and "accept" of requests
  # * test search for hidden objects
  # * test public controller
  # * test tag controller
  # For binary access
  # * test aggregate creation
  # * test kiwi live image file creation
  # * test kiwi product file creation

  # Everything needs to be tested as user with various roles and as a group member with various roles

  # the very same must be tested also for public project, but protected package
  def test_deleted_projectlist
    prepare_request_valid_user
    get "/source?deleted"
    assert_response 403
    assert_match /only admins can see deleted projects/, @response.body 

    prepare_request_with_user "king", "sunflower"
    get "/source?deleted"
    assert_response :success
    # can't do any check on the list without also deleting projects, which is too much for this test
    assert_tag( :tag => "directory" )
  end 
end
