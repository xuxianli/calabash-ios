require 'calabash-cucumber/core'

module Calabash
  module Cucumber
    module TestsHelpers
      include Calabash::Cucumber::Core

      def navigation_path(*args)

        #navigation_path(
        #    [:a , 2],
        #    [""],
        #)


      end

      def query_map(uiquery,prop, *args)
        query(uiquery,*args).map {|o| o[prop.to_s]}
      end

      def classes(uiquery,*args)
        query_map(uiquery,:class,*args)
      end

      def element_does_not_exist(uiquery)
        query(uiquery).empty?
      end

      def element_exists(uiquery)
        not element_does_not_exist(uiquery)
      end

      def marked(expected_mark)
        "view marked:'#{expected_mark}'"
      end

      def view_with_mark_exists(expected_mark)
        element_exists(marked(expected_mark))
      end

      def check_element_exists(query)
        if not element_exists(query)
          screenshot_and_raise "No element found for query: #{query}"
        end
      end

      def check_element_does_not_exist(query)
        if element_exists(query)
          screenshot_and_raise "Expected no elements to match query: #{query}"
        end
      end

      def check_view_with_mark_exists(expected_mark)
        check_element_exists(marked(expected_mark))
      end

      def screenshot_and_raise(msg, options={:prefix => nil, :name => nil, :label => nil})
        screenshot_embed(options)
        raise(msg)
      end

      def fail(msg="Error. Check log for details.", options={:prefix => nil, :name => nil, :label => nil})
        screenshot_and_raise(msg, options)
      end

      def each_cell(opts={:query => "tableView", :post_scroll => 0.3, :animate => true}, &block)
        uiquery = opts[:query] || "tableView"
        skip = opts[:skip_if]
        check_element_exists(uiquery)
        secs = query(uiquery,:numberOfSections).first
        secs.times do |sec|
          rows = query(uiquery,{:numberOfRowsInSection => sec}).first
          rows.times do |row|
            next if skip and skip.call(row,sec)
            scroll_opts = {:section => sec, :row => row}.merge(opts)
            scroll_to_cell(scroll_opts)
            sleep(opts[:post_scroll]) if opts[:post_scroll] and opts[:post_scroll] > 0
            yield(row, sec)
          end
        end
      end

      def each_cell_and_back(opts={:query => "tableView",
                                   :post_scroll => 0.3,
                                   :post_back => 0.5,
                                   :post_tap_cell => 0.3,
                                   :animate => true}, &block)
        back_query = opts[:back_query] || "navigationItemButtonView"
        post_tap_cell = opts[:post_tap_cell] || 0.3
        post_back = opts[:post_back] || 0.6


        each_cell(opts) do |row, sec|
          touch("tableViewCell indexPath:#{row},#{sec}")
          wait_for_elements_exist([back_query])
          sleep(post_tap_cell) if post_tap_cell > 0

          yield(row,sec) if block_given?

          touch(back_query)

          sleep(post_back) if post_back > 0

        end
      end


      def screenshot_embed(options={:prefix => nil, :name => nil, :label => nil})
        path = screenshot(options)
        embed(path, "image/png", options[:label] || File.basename(path))
      end

      def screenshot(options={:prefix => nil, :name => nil})
        prefix = options[:prefix]
        name = options[:name]

        @@screenshot_count ||= 0
        res = http({:method => :get, :path => 'screenshot'})
        prefix = prefix || ENV['SCREENSHOT_PATH'] || ""
        if name.nil?
          name = "screenshot"
        else
          if File.extname(name).downcase == ".png"
            name = name.split(".png")[0]
          end
        end

        path = "#{prefix}#{name}_#{@@screenshot_count}.png"
        File.open(path, 'wb') do |f|
          f.write res
        end
        @@screenshot_count += 1
        path
      end


    end
  end
end
