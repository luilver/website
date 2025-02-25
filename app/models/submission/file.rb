class Submission::File < ApplicationRecord
  belongs_to :submission

  URI_REGEX = %r{s3://(?<bucket>[a-z0-9-]+)/(?<key>.*)}.freeze

  before_create do
    self.uri = "s3://#{Exercism.config.aws_submissions_bucket}/#{Rails.env}/storage/#{SecureRandom.compact_uuid}"
  end

  # When the object is created we want to save
  # any content that has been passed in via the
  # attr_writer. We only want to do this on create
  # and never want to update or change this content.
  after_create do
    if @content
      Exercism.s3_client.put_object(
        bucket: s3_bucket,
        key: s3_key,
        body: @content,
        acl: 'private'
      )
    end
    write_to_efs!
  end

  def efs_path
    [
      Exercism.config.efs_submissions_mount_point,
      submission.uuid,
      filename
    ].join("/")
  end

  def write_to_efs!
    FileUtils.mkdir_p(efs_path.split("/").tap(&:pop).join("/"))
    File.open(efs_path, 'w') { |f| f.write(content) }
  end

  def content=(val)
    @content = val.force_encoding('utf-8')
  end

  def content
    # Don't use `.presence?` here as the encoding might be incorrect
    # and then the string check will raise an exception
    return @content if @content && @content != ""
    return file_contents if uri.empty?

    Exercism.s3_client.get_object(
      bucket: s3_bucket,
      key: s3_key
    ).body.read
  end

  def s3_bucket
    URI_REGEX.match(uri)[:bucket]
  end

  def s3_key
    URI_REGEX.match(uri)[:key]
  end
end
