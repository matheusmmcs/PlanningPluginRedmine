(function($){
	$(document).ready(function(){

		var PLANNING_USER = 'planning-user';

		var PLANNING_USER_CONTENT = '.'+PLANNING_USER+"-content";
		var PLANNING_USER_CLASS = '.'+PLANNING_USER;
		var PLANNING_USER_ISSUES_CLOSED = PLANNING_USER+'-closed';
		var PLANNING_USER_ISSUES_CLOSED_CLASS = '.'+PLANNING_USER_ISSUES_CLOSED;
		var PLANNING_USER_ISSUES_IN_PROGRESS = PLANNING_USER+'-in-progress';
		var PLANNING_USER_ISSUES_IN_PROGRESS_CLASS = '.'+PLANNING_USER_ISSUES_IN_PROGRESS;

		var ISSUE_TABLE_WRAPPER = '.issue-table-wrapper';
		var ISSUE_CLOSED_TABLE_WRAPPER = '.issue-closed-table-wrapper';
		var ISSUE_IN_PROGRESS_TABLE_WRAPPER = '.issue-in-progress-table-wrapper';
		


		$(PLANNING_USER_CONTENT).addClass(PLANNING_USER+'--active-animation')
							.addClass(PLANNING_USER_ISSUES_CLOSED+'--active-animation')
							.addClass(PLANNING_USER_ISSUES_IN_PROGRESS+'--active-animation');


		$('.planning-user-details').on('click', function(e) {
			evtToogleTable(e, $(this), ISSUE_TABLE_WRAPPER, PLANNING_USER);
		});

		$('.planning-user-closed-details').on('click', function(e) {
			evtToogleTable(e, $(this), ISSUE_CLOSED_TABLE_WRAPPER, PLANNING_USER_ISSUES_CLOSED);
		});

		$('.planning-user-in-progress-details').on('click', function(e) {
			evtToogleTable(e, $(this), ISSUE_IN_PROGRESS_TABLE_WRAPPER, PLANNING_USER_ISSUES_IN_PROGRESS);
		});

		function evtToogleTable(evt, $this, tableWrapperClass, planningUserActiveClass) {
			evt.preventDefault();
			var $planningUser = $this.closest(PLANNING_USER_CLASS);

			if (!$planningUser.length) {
				$planningUser = $this.closest(PLANNING_USER_CONTENT);
			}
			
			var	$table = $planningUser.find(tableWrapperClass),
				openClass = planningUserActiveClass+'--active';

			toogleTable($this, $planningUser, $table, openClass);
		}

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