(function($){
	$(document).ready(function(){

		var PLANNING_USER = 'planning-user';
		var PLANNING_USER_CLASS = '.'+PLANNING_USER;
		var PLANNING_USER_ISSUES_CLOSED = PLANNING_USER+'-closed';
		var PLANNING_USER_ISSUES_CLOSED_CLASS = '.'+PLANNING_USER_ISSUES_CLOSED;
		var ISSUE_TABLE_WRAPPER = '.issue-table-wrapper';
		var ISSUE_CLOSED_TABLE_WRAPPER = '.issue-closed-table-wrapper';
		


		$(PLANNING_USER_CLASS).addClass(PLANNING_USER+'--active-animation')
							.addClass(PLANNING_USER_ISSUES_CLOSED+'--active-animation')


		$('.planning-user-details').on('click', function(e) {
			e.preventDefault();
			var $this = $(this),
				$planningUser = $this.closest(PLANNING_USER_CLASS),
				$table = $planningUser.find(ISSUE_TABLE_WRAPPER),
				openClass = PLANNING_USER+'--active';
			toogleTable($this, $planningUser, $table, openClass)				
		});

		$('.planning-user-closed-details').on('click', function(e) {
			e.preventDefault();
			var $this = $(this),
				$planningUser = $this.closest(PLANNING_USER_CLASS),
				$table = $planningUser.find(ISSUE_CLOSED_TABLE_WRAPPER),
				openClass = PLANNING_USER_ISSUES_CLOSED+'--active';
			toogleTable($this, $planningUser, $table, openClass)				
		});

		function toogleTable($this, $planningUser, $table, openClass){
			if ($planningUser.hasClass(openClass)) {
				$planningUser.removeClass(openClass);
				$table.hide();
				$this.removeClass('arrow_up');
				$this.addClass('arrow_down');
			} else {
				$planningUser.addClass(openClass);
				$table.show();
				$this.addClass('arrow_up');
				$this.removeClass('arrow_down');
			}
		}

	});
})(jQuery);