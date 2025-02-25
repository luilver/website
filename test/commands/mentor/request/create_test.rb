require "test_helper"

class Mentor::Request::CreateTest < ActiveSupport::TestCase
  test "creates request" do
    user = create :user
    solution = create :practice_solution, user: user
    create :user_track, user: user, track: solution.track
    comment = "Please help with this"

    Mentor::Request::Create.(solution, comment)

    assert_equal 1, Mentor::Request.count

    request = Mentor::Request.last
    assert_equal solution, request.solution
    assert_equal comment, request.comment_markdown
  end

  test "returns existing in progress request" do
    user = create :user
    solution = create :practice_solution, user: user
    create :user_track, user: user, track: solution.track
    existing_request = create :mentor_request, status: :pending, solution: solution

    new_request = Mentor::Request::Create.(solution, "foobar")
    assert_equal existing_request, new_request
  end

  test "creates new request if there is a fulfilled one" do
    existing_request = create :mentor_request, status: :fulfilled
    create :user_track, user: existing_request.solution.user, track: existing_request.solution.track

    new_request = Mentor::Request::Create.(existing_request.solution, "some copy")
    refute_equal existing_request, new_request
  end

  test "fails if no slots are avalable" do
    solution = create :practice_solution
    create :user_track, user: solution.user, track: solution.track
    solution.user_track.expects(num_available_mentoring_slots: 0)

    assert_raises NoMentoringSlotsAvailableError do
      Mentor::Request::Create.(solution, "some copy")
    end
  end
end
