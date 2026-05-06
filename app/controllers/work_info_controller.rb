def index
  @user = current_user
  if !(@user) || @user.admin
    flash[:error] = "Apologies, looks like something went wrong"
    redirect_to home_dashboard_index_path
  end
end