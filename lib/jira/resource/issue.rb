require 'cgi'

module JIRA
  module Resource

    class IssueFactory < JIRA::BaseFactory # :nodoc:
    end

    class Issue < JIRA::Base

      has_one :reporter,  :class => JIRA::Resource::User,
                          :nested_under => 'fields'
      has_one :assignee,  :class => JIRA::Resource::User,
                          :nested_under => 'fields'
      has_one :project,   :nested_under => 'fields'

      has_one :issuetype, :nested_under => 'fields'

      has_one :priority,  :nested_under => 'fields'

      has_one :status,    :nested_under => 'fields'

      has_many :components, :nested_under => 'fields'

      has_many :comments, :nested_under => ['fields','comment']

      has_many :attachments, :nested_under => 'fields',
                          :attribute_key => 'attachment'

      has_many :versions, :nested_under => 'fields'

      has_many :worklogs, :nested_under => ['fields','worklog']

      def self.all(client, jql = nil)
        issues = []
        fetched_results = 0
        begin 
          url = client.options[:rest_base_path] + "/search?startAt=#{fetched_results}"
          url << "&jql=#{ URI.escape(jql) }" if jql
          url << "&expand=all"

          response = client.get(url)
          json = parse_json(response.body)
          
          issues = issues + json['issues'].map do |issue|
            client.Issue.build(issue)
          end

          fetched_results += json['maxResults']

        end while fetched_results < json['total']

        issues
      end

      def changelogs
        change_histories = []

        url = client.options[:rest_base_path] + "/issue/#{id}?expand=changelog"
        response = client.get(url)
        json = self.class.parse_json(response.body)
        change_histories = json['changelog']['histories'].map do |h|
          client.Changelog.build(h)
        end
        change_histories

      end

      def self.jql(client, jql)
        url = client.options[:rest_base_path] + "/search?jql=" + CGI.escape(jql)
        response = client.get(url)
        json = parse_json(response.body)
        json['issues'].map do |issue|
          client.Issue.build(issue)
        end
      end

      def respond_to?(method_name)
        if attrs.keys.include?('fields') && attrs['fields'].keys.include?(method_name.to_s)
          true
        else
          super(method_name)
        end
      end

      def method_missing(method_name, *args, &block)
        if attrs.keys.include?('fields') && attrs['fields'].keys.include?(method_name.to_s)
          attrs['fields'][method_name.to_s]
        else
          super(method_name)
        end
      end

    end

  end
end
