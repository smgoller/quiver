module Quiver
  class RouteHelper
    def initialize(router)
      self.router = router
    end

    def path(*args)
      route = router.path(*args)
      route.gsub(/%7B(.*?)%7D/, '{\1}')
    end

    private

    attr_accessor :router
  end
end
