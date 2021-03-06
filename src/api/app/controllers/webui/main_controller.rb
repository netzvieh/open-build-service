class Webui::MainController < Webui::WebuiController

  include Webui::WebuiHelper
  include StatisticsCalculations

  # permissions.status_message_create
  before_filter :require_admin, only: [:delete_message, :add_news]
  skip_before_action :check_anonymous, only: [:index]

  def gather_busy
    busy = []
    archs = Architecture.where(available: 1).pluck(:name).map { |arch| map_to_workers(arch) }.uniq
    archs.each do |arch|
      starttime = Time.now.to_i - 168.to_i * 3600
      rel = StatusHistory.where("time >= ? AND \`key\` = ?", starttime, 'building_' + arch)
      values = rel.pluck(:time, :value).collect { |time, value| [time.to_i, value.to_f] }
      values = StatusHelper.resample(values, 400)
      if busy.empty?
        busy = values
      elsif values.present?
        busy = Webui::MonitorController.addarrays(busy, values)
      end
    end
    busy
  end

  def index
    @news = StatusMessage.alive.limit(4).to_a
    @workerstatus = Rails.cache.fetch('workerstatus_hash', expires_in: 10.minutes) do
      WorkerStatus.hidden.to_hash
    end
    @latest_updates = get_latest_updated(6)
    @waiting_packages = 0
    @building_workers = @workerstatus.elements('building').length
    @overall_workers = @workerstatus['clients']
    @workerstatus.elements('waiting') { |waiting| @waiting_packages += waiting['jobs'].to_i }
    @busy = Rails.cache.fetch('mainpage_busy', expires_in: 10.minutes) do
      gather_busy
    end
    @project_count = Project.count
    @package_count = Package.count
    @repo_count = Repository.count
    @user_count = User.count
  end

  def sitemap
    render :layout => false, :content_type => 'application/xml'
  end

  def require_projects
    @projects = Project.all.pluck(:name)
  end

  def sitemap_projects
    require_projects
    render :layout => false, :content_type => 'application/xml'
  end

  def sitemap_packages
    category = params[:category].to_s

    projects=Project.arel_table
    if category =~ %r{home}
      rel = Project.where(projects[:name].matches("#{category}%"))
    elsif category == 'opensuse'
      rel = Project.where(projects[:name].matches('openSUSE:%'))
    else
      rel = Project.all.where.not(projects[:name].matches('home:%'))
      rel = rel.where.not(projects[:name].matches('DISCONTINUED:%'))
      rel = rel.where.not(projects[:name].matches('openSUSE:%'))
    end
    projects = {}
    rel.pluck(:id, :name).each do |id, name|
      projects[id] = name
    end
    result = Package.where(project_id: projects.keys).pluck(:project_id, :name)
    @packages = Array.new
    result.each do |pid, name|
      @packages << [projects[pid], name]
    end
    render :template => 'webui/main/sitemap_packages',
           :layout => false, :locals => {:action => params[:listaction]},
           :content_type => 'application/xml'
  end

  def add_news_dialog
    render_dialog
  end

  def add_news
    if params[:message].nil? or params[:severity].empty?
      flash[:error] = 'Please provide a message and severity'
      redirect_to(:action => 'index') and return
    end
    #TODO - make use of permissions.status_message_create
    StatusMessage.create!(message: params[:message], severity: params[:severity], user: User.current)
    redirect_to(:action => 'index')
  end

  def delete_message_dialog
    render_dialog
  end

  def delete_message
    required_parameters :message_id
    StatusMessage.find(params[:message_id]).delete
    redirect_to(:action => 'index')
  end

end
