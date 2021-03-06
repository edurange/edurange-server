class Scenario < ActiveRecord::Base
  require 'open-uri'

  enum location: {
    #development:0,
    production: 1,
    #local: 2,
    #custom: 3,
    test: 4
  }

  # scenario status lifecycle
  #
  #     archived
  #        ^
  #        |  archive!/unarchive!
  #        v
  # --> stopped <-------------------\
  #        |                        |
  #        | start!                 |
  #        v                        |
  #     starting <--> error <--> stopping
  #        |                        ^
  #        |                        |
  #        V            stop!       |
  #     started --------------------/

  enum status: {
    stopped: 0,
    started: 4,
    starting: 2,
    stopping: 12,
    error: 3,
    archived: 14
  }

  def can_start?
    valid_transition?(status, 'starting')
  end

  def can_stop?
    valid_transition?(status, 'stopping')
  end

  def can_archive?
     !archived? & stopped?
  end

  def can_unarchive?
    archived?
  end

  def can_destroy?
    stopped? | archived?
  end

  def can_restart?
    started? | error?
  end

  def valid_transition?(old, new)
    logger.debug("testing state transition #{old} to #{new}")
    case new
    when 'stopped'
      ['stopping', 'archived'].include?(old)
    when 'stopping'
      ['started', 'error'].include?(old)
    when 'started'
      'starting' == old
    when 'starting'
      ['stopped', 'error'].include?(old)
    when 'archived'
      'stopped' == old
    when 'error'
      ['starting', 'stopping'].include?(old)
    else
      false
    end
  end

  validate def state_machine_valid?
    if status_changed? & !valid_transition?(status_was, status) then
      errors.add(:status, "Can not update state from #{status_was} to #{status}")
      false
    else
      true
    end
  end
  
  def only_delete_if_stopped_or_archived
    errors.add(:status, 'must be stopped or archived to destroy') unless can_destroy?
  end

  before_destroy do
    only_delete_if_stopped_or_archived
    throw(:abort) if errors.present?
  end

  def self.not_archived
    where.not(status: 'archived')
  end

  belongs_to :user
  has_many :questions, dependent: :destroy
  has_many :groups,    dependent: :destroy
  has_many :instances,  dependent: :destroy
  has_many :players, through: :groups

  has_many :variable_templates
  has_many :variables

  validates_associated :questions, :groups, :user, :instances

  validates :user, presence: true

  validates :name, presence: true, format: {
    with: /\A\w*\z/,
    message: "can only contain alphanumeric and underscore"
  }

  validates :uuid, presence: true, format: {
    with: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/,
    message: 'Invalid UUID format'
  }

  after_initialize def set_defaults
    self.uuid ||= SecureRandom.uuid
  end

  validate :paths_exist, :owner_is_instructor_or_admin

  validate def paths_exist
    errors.add(:path, "#{path} does not exist") unless File.exists? path
    errors.add(:path, "#{path_yml} does not exist") unless File.exists? path_yml
  end

  alias owner user

  validate def owner_is_instructor_or_admin
    unless owner.admin? or owner.instructor?
      errors.add(:user, 'Only admins and instructors create scenarios.')
    end
  end

  before_destroy do
    terraform.clean!
  end

  def self.path(location, name)
    Rails.root.join('scenarios', location.to_s, name.to_s.downcase)
  end

  def self.path_yml(location, name)
    Scenario.path(location, name).join("#{name.downcase}.yml")
  end

  def path
    Scenario.path(location, name)
  end

  def path_yml
    Scenario.path_yml(location, name)
  end

  def owner?(id)
    return self.user_id == id
  end

  def scenario
    return self
  end

  def students
    students = []
    self.groups.each do |group|
      group.players.each do |player|
        students << player.user if not students.include? player.user and player.user
      end
    end
    students
  end

  def questions_answered(user)
    return nil if not self.has_student? user

    answered = 0
    self.questions.each do |question|
      answered += 1 if question.answers.where("user_id = ?", user.id).size > 0
    end
    answered
  end

  def questions_correct(user)
    return nil if not self.has_student? user

    correct = 0
    self.questions.each do |question|
      # correct += 1 if question.answers.where("user_id = ? AND correct = 1", user.id).size > 0
      question.answers.where("user_id = ?", user.id).each do |answer|
        correct += 1 if answer.correct
      end
    end
    correct
  end

  def has_student?(user)
    return false if not user
    self.groups.each do |group|
      return true if group.players.select { |p| p.user == user }.size > 0
    end
    false
  end

  def has_question?(question)
    self.questions.find_by_id(question.id) != nil
  end

  def answer_cnt(user)
    return nil if not has_student?(user)
    cnt = 0
    self.questions.each do |question|
      cnt += question.answers.where("user_id = ?", user.id).size
    end
    cnt
  end

  def answers_list(user)
    return nil if not has_student?(user)
    answers = []
    self.questions.each do |question|
      answers += question.answers.map { |a| a.id }
    end
    answers
  end

  def students_groups(user)
    groups = []
    self.groups.each do |group|
      group.players.each do |player|
        if player.user
          groups << group if player.user == user
        end
      end
    end
    groups
  end

  def instantiate_variable template
    self.variables << template.instantiate
  end

  def self.load(**args)
    ScenarioLoader.new(args).fire!
  end

  def guide_exists?
    guide_path.exist?
  end

  def guide
    guide_path.read
  end

  def guide_path
    documentation_path + "#{self.name.downcase}.md"
  end

  def solution
    solution_path.read
  end

  def solution_path
    documentation_path + "#{self.name.downcase}_solution.md"
  end

  def solution_exists?
    solution_path.exist?
  end

  def documentation_path
    Rails.root.join('documentation', 'scenarios')
  end

  # list all scenarios available to create
  def self.templates
    Rails.root.join('scenarios').children.flat_map do |location|
      if location.directory? then
        location.children.flat_map do |scenario|
          if scenario.directory?
            yml_path = scenario.join("#{scenario.basename}.yml")
            hash = YAML.load_file(yml_path)
            Scenario.new(
              name: hash['Name'],
              location: location.basename.to_s,
              description: hash['Description']
            )
          end
        end
      end
    end
  end

  def import_bash_histories!
    s3 = Aws::S3::Resource.new(region: 'us-east-1')
    bucket = s3.bucket('edurange')
    objects = bucket.objects(prefix: "scenarios/#{scenario.uuid}/bash_history/")
    objects.each do |object|
      object.get.body.read.each_line do |line|
        record = JSON.parse(line)
        begin
          BashHistory.find_or_create_by!(
            instance:     self.instances.find_by_name(record['host'].gsub('-', '_')),
	    begin:        record['begin'],
	    cwd:          record['cwd'],
	    command:      record['cmd'],
	    output:       record['output'].gsub(/#%#/, "\n"),
	    player:       self.players.find_by_login(record['prompt'].gsub(/@.*$/, '')),
	    prompt:       record['prompt'],
	    performed_at: Time.at(record['time'].to_i),
	    time:         record['time'].to_i
          )
        rescue ActiveRecord::RecordInvalid
          logger.warn("could not save bash history record: #{$!}")
        end
      end
      object.delete
    end
  end

  def schedule_import_bash_histories!
    ImportBashHistories.set(wait: 1.minute).perform_later(self)
  end

  def terraform
    @terraform ||= TerraformScenario.new(self)
  end

  def start!
    self.starting!
    terraform.init!
    terraform.apply!
    terraform.output!
    self.schedule_import_bash_histories!
    self.started!
  rescue
    self.error!
    raise
  end

  def stop!
    self.stopping!
    terraform.destroy!
    self.instances.each do |i|
      i.update_attributes!(
        ip_address_public: nil,
        ip_address_private: nil
      )
    end
    self.stopped!
  rescue
    self.error!
    raise
  end

  def restart!
    stop!
    start!
  end

  def archive!
    archived!
  end

  def unarchive!
    stopped!
  end

end
