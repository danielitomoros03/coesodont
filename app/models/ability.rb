# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)

    alias_action :create, :read, :update, :export, to: :crue
    alias_action :read, :update, to: :ru
    alias_action :create, :read, to: :cr
    alias_action :create, :update, to: :cu
    alias_action :create, :update, :export, to: :cue

    user ||= User.new

    if user.admin?
      can :access, :rails_admin
      can :manage, :dashboard
      cannot :import, :all
      can :import, [User, Student, Teacher, Subject, Period, AcademicRecord, Billboard]

      if user.admin.yo?
        can :manage, :all
      elsif user.admin.jefe_control_estudio?
        can :manage, [Admin, Student, Teacher, Area, Subject, Bank, BankAccount, PaymentReport, Course, Grade, AcademicProcess, EnrollAcademicProcess, AcademicRecord, Section, AdmissionType, PeriodType, Address, StudyPlan, Period, Dependency, Schedule, EnrollmentDay, Billboard]
        can :crue, [School, User, Faculty]
      else
        cannot :manage, [User, Admin, Student, Teacher, Area, Subject, School, Bank, BankAccount, PaymentReport, Course, Grade, AcademicProcess, EnrollAcademicProcess, AcademicRecord, Section, AdmissionType, PeriodType, Address]
      end
    end
  end
end
