class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  private

  def admin?
    user.has_role?(:admin)
  end

  def lead?
    user.has_role?(:lead)
  end

  def analyst?
    user.has_role?(:analyst)
  end

  def scout?
    user.has_role?(:scout)
  end

  def admin_or_lead?
    admin? || lead?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    def admin?
      user.has_role?(:admin)
    end

    def lead?
      user.has_role?(:lead)
    end

    def analyst?
      user.has_role?(:analyst)
    end

    def scout?
      user.has_role?(:scout)
    end

    def admin_or_lead?
      admin? || lead?
    end
  end
end
