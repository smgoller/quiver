module Quiver
  class Error
    attr_reader :type, :subject

    def initialize(subject, type)
      if type.is_a?(Symbol)
        @type = type
      else
        @type = type.dup.freeze if type
      end

      if subject.is_a?(Symbol)
        @subject = subject
      else
        @subject = subject.dup.freeze if subject
      end
    end

    def ==(other)
      type == other.type &&
        subject == other.subject
    end
  end
end
