require File.expand_path('../../test_helper', __FILE__)

class IssuePatchTest < ActiveSupport::TestCase
  def expect_root_issue_to_be_created
    issue = build_issue_with @root_tracker_1
    issue.save
    assert issue.valid?
  end

  def expect_child_issue_to_be_created
    parent = build_issue_with @root_tracker_1
    parent.save!
    child = build_issue_with @first_child_tracker, parent
    child.save
    assert child.valid?
  end

  def expect_child_of_child_to_be_created
    parent = build_issue_with @root_tracker_1
    parent.save!
    first_child = build_issue_with @first_child_tracker, parent
    first_child.save!
    second_child = build_issue_with @second_child_tracker, first_child
    second_child.save
    assert second_child.valid?
  end

  test 'Issue is patched with RedmineRestrictTracker::Patches::IssuePatch' do
    patch = RedmineRestrictTracker::Patches::IssuePatch
    assert_includes Issue.included_modules, patch
    %i(restrict_tracker restrict_root restrict_parent).each do |method|
      assert_includes Issue.instance_methods, method,
        "#{ method } method not included in Issue"
    end
  end

  # Without plugin settings defined
  test 'creating a root issue without settings' do
    create_base_setup
    expect_root_issue_to_be_created
  end

  test 'creating the clild of a root issue without settings' do
    create_base_setup
    expect_child_issue_to_be_created
  end

  test 'creating the clild of a child issue without settings' do
    create_base_setup
    expect_child_of_child_to_be_created
  end

  # With plugin settings defined
  test 'creating a root issue with settings' do
    create_base_setup_with_settings
    expect_root_issue_to_be_created
  end

  test 'creating the clild of a root issue with settings' do
    create_base_setup_with_settings
    expect_child_issue_to_be_created
  end

  test 'creating the clild of a child issue with settings' do
    create_base_setup_with_settings
    expect_child_of_child_to_be_created
  end

  test 'not creating a child issue without a parent' do
    create_base_setup_with_settings
    issue = build_issue_with @first_child_tracker
    issue.save
    errors = issue.errors.messages
    assert_not_empty errors
    assert_equal 1, errors.size
    assert_not_nil errors[:base]
    assert_equal ["#{ @first_child_tracker.name } can not be a root node, "\
      "please assign a parent!"], errors[:base]
  end

  test 'not creating an always root issue with a parent' do
    create_base_setup_with_settings
    parent = build_issue_with @root_tracker_1
    parent.save!
    always_root = build_issue_with @always_root_tracker, parent
    always_root.save
    errors = always_root.errors.messages
    assert_not_empty errors
    assert_equal 1, errors.size
    assert_not_nil errors[:base]
    assert_equal ["#{ @always_root_tracker.name.pluralize } can not be set "\
      "as children!"], errors[:base]
  end

  test 'not creating child with the wrong tracker and one possible parent' do
    create_base_setup_with_settings
    parent = build_issue_with @root_tracker_2
    parent.save!
    wrong_child = build_issue_with @first_child_tracker, parent
    wrong_child.save
    errors = wrong_child.errors.messages
    assert_not_empty errors
    assert_equal 1, errors.size
    assert_not_nil errors[:base]
    assert_equal ["#{ @first_child_tracker.name.pluralize } can only be "\
      "children of #{ @root_tracker_1.name.pluralize }!"], errors[:base]
  end

  test 'not creating child with the wrong tracker and many possible parents' do
    create_base_setup_with_settings
    parent = build_issue_with @root_tracker_1
    parent.save!
    wrong_child = build_issue_with @second_child_tracker, parent
    wrong_child.save
    errors = wrong_child.errors.messages
    assert_not_empty errors
    assert_equal 1, errors.size
    assert_not_nil errors[:base]
    assert_equal ["#{ @second_child_tracker.name.pluralize } can only be "\
      "children of #{ @root_tracker_2.name.pluralize } and "\
      "#{ @first_child_tracker.name.pluralize }!"], errors[:base]
  end
end
