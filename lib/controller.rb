# frozen_string_literal: true

require_relative 'view'
require_relative 'service'
require_relative '../test/text_analyzer'
require 'nokogiri'

class Controller
  def initialize
    @view = View.new
    @service = Service.new
    @text_analyzer = TextAnalyzer.new
  end

  def search_internet_for_company
    companies = search_for_company
    return @view.invalid_name if companies.count == 1 || companies.empty?

    company_names = generate_company_selection(companies)
    index = @view.display_list_and_select(company_names)
    @view.retrieving(company_names[index], 'annual reports')
    reports = @service.get_reports(companies[index])
    return @view.reports_not_found if reports.empty?

    report_dates = generate_report_selection(reports)
    index = @view.display_list_and_select(report_dates)
    paragraphs = search_for_paragraphs(reports, index)
    paragraphs == -1 ? @view.reports_not_found : display_paragraphs(paragraphs)
  end

  private

  def display_paragraphs(paragraphs)
    core_sentences = search_for_core_sentences(paragraphs)
    core_sentences.each do |sentence|
      @view.display_answers(sentence)
    end
    @view.display_answers(paragraphs) if @view.ask_for_full_paragraphs
  end

  def search_for_core_sentences(paragraphs)
    core_sentences = []
    paragraphs.each do |paragraph|
      core_sentences.append(@text_analyzer.analyze(paragraph))
    end
    core_sentences
  end

  def search_for_company
    name = @view.ask_for('company')
    @view.looking_for(name)
    @service.get_companies(name)
  end

  def search_for_paragraphs(reports, index)
    url = @service.extract_report_url(reports[index])
    url == -1 ? url : @service.analyze_report(url)
  end

  def generate_company_selection(companies)
    company_names = []
    companies.each do |company|
      company_names.append(@service.get_company_name(company))
    end
    return company_names
  end

  def generate_report_selection(reports)
    report_dates = []
    reports.each do |report|
      report_dates.append(report.search('td')[3].text)
    end
    return report_dates
  end
end
