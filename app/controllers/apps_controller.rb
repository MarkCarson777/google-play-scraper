class AppsController < ApplicationController
  def results
    app_id = params[:app_id]
    if app_id.blank?
      flash[:error] = "Please enter an app ID."
      redirect_to search_apps_path and return
    end

    @app_data = GooglePlayScraper.fetch_app_details(app_id)
    Rails.logger.info "App Data: #{@app_data.inspect}"  # Log the data for debugging
    if @app_data.nil?
      flash[:error] = "Unable to fetch app data for '#{app_id}'."
      redirect_to search_apps_path and return
    end
    render 'search'
  end
end
