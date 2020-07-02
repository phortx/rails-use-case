# Rails Use Case gem

Opinionated gem for UseCases and Services in rails to keep models and controllers slim.

The purpose of a UseCase is to contain reusable high level business logic which would normally be
located in the controller. Examples are: Place an item in the cart, create a new user or delete a comment.

The purpose of a Service is to contain low level non-domain code like communication with a API,
generating an export, upload via FTP or generating a PDF.


## Setup

```ruby
gem 'rails_use_case'
```


## Use Case

The purpose of a UseCase is to contain reusable high level business logic which would normally be
located in the controller. It defines a process via `step` definitions. A UseCase takes params
and has a outcome, which is either successful or failed. It doesn't have a configuration file and doesn't
log anything. Examples are: Place an item in the cart, create a new user or delete a comment.

Steps are executed in the defined order. Only when a step succeeds (returns true) the next step will
be executed. Steps can be skipped via `if` and `unless`.

The UseCase should assign the main record to `@record`. Calling save! without argument will try to
save that record or raises an exception. Also the `@record` will automatically passed into the outcome.

The params should always passed as hash and are automatically assigned to instance variables.

Use Cases should be placed in the `app/use_cases/` directory and the file and class name should start with a verb like `create_blog_post.rb`.


### Example UseCase

```ruby
class CreateBlogPost < Rails::UseCase
  attr_accessor :title, :content, :author, :skip_notifications

  validates :title, presence: true
  validates :content, presence: true
  validates :author, presence: true

  step :build_post
  step :save!
  step :notify_subscribers, unless: -> { skip_notifications }


  private def build_post
    @record = BlogPost.new(
      title: title,
      content: content,
      created_by: author,
      type: :default
    )
  end

  private def notify_subscribers
    # ... send some mails ...
  end
end
```

Example usage of that UseCase:

```ruby
result = CreateBlogPost.perform(
  title: 'Super Awesome Stuff!',
  content: 'Lorem Ipsum Dolor Sit Amet',
  created_by: current_user,
  skip_notifications: false
)

puts result.inspect
# => {
#   success: true,
#   record: BlogPost(...)
#   errors: [],
#   error: nil
# }
```


## Behavior

A behavior is simply a module that contains methods to share logic between use cases and to keep them DRY.

To use a behavior in a use case, use the `with` directive, like `with BlogPosts`.

Behaviors should be placed in the `app/behaviors/` directory and the file and module name should named in a way it can be prefixed with `with`, like `blog_posts.rb` (with blog posts).


### Example Behavior

Definition:

```ruby
module BlogPosts
  def notify_subscribers
    # ... send some mails ...
  end
end
```

Usage:

```ruby
class CreateBlogPost < Rails::UseCase
  with BlogPosts

  # ...

  step :build_post
  step :save!
  step :notify_subscribers, unless: -> { skip_notifications }

  # ...
end
```



## Service

The purpose of a Service is to contain low level non-domain code like communication with a API,
generating an export, upload via FTP or generating a PDF. It takes params, has it's own configuration and writes a log file.

It comes with call style invocation: `PDFGenerationService.(some, params)`

Services should be placed in the `app/services/` directory and the name should end with `Service` like `PDFGenerationService` or `ReportUploadService`.


### Example Service

```ruby
class PDFGenerationService < Rails::Service
  attr_reader :pdf_template, :values

  # Constructor.
  def initialize
    super 'pdf_generation'
    prepare
    validate_libreoffice
  end


  # Entry point.
  #
  # @param [PdfTemplate] pdf_template PdfTemplate record.
  # @param [Hash<String, String>] values Mapping of variables to their values.
  #
  # @returns [String] Path to PDF file.
  def call(pdf_template, values = {})
    @pdf_template = pdf_template
    @values = prepare_variable_values(values)

    write_odt_file
    replace_variables
    generate_pdf

    @pdf_file_path
  ensure
    delete_tempfile
  end
end
```

### Configuration

The service tries to automatically load a configuration from `config/services/[service_name].yml`
which is available via the `config` method.


### Logging

Each service automatically logs to a separate log file `log/services/[service_name].log`. You can write additional logs via `logger.info(msg)`.

It's possible to force the services to log to STDOUT by setting the environment variable `SERVICE_LOGGER_STDOUT`. This is useful for Heroku for example.


## License

MIT
