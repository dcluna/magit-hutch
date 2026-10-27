;;; hutch-agent-test.el --- Test the agent callback loop -*- lexical-binding: t; -*-

;;; Code:

(require 'ert)

(let ((hutch-dir (file-name-directory
                  (directory-file-name
                   (file-name-directory load-file-name)))))
  (add-to-list 'load-path hutch-dir)
  (require 'hutch-agent))

(defun hat--run (response info &optional result)
  "Feed RESPONSE and INFO to the agent callback.
RESULT pre-fills the result box.  Return the (TYPE MSG) error, or nil."
  (let* ((err        nil)
         (result-box (hutch--make-result-box)))
    (when result (hutch--result-box-set result-box result))
    (hutch--agent-request response info
                          #'ignore
                          (lambda (type msg) (setq err (list type msg)))
                          nil
                          result-box
                          (hutch--make-result-box)
                          (hutch--make-result-box)
                          40
                          "scope")
    err))

(ert-deftest hutch-agent-test-stream-text-chunk-ignored ()
  (should-not (hat--run "Looking at the diff" '(:stream t))))

(ert-deftest hutch-agent-test-stream-end-with-pending-tool ()
  (should-not (hat--run t '(:stream t :tool-use ((:name "read_file"))))))

(ert-deftest hutch-agent-test-stream-end-after-submit ()
  (should-not (hat--run t '(:stream t) '(finding))))

(ert-deftest hutch-agent-test-stream-end-without-tool ()
  (should (eq 'no-submit (car (hat--run t '(:stream t))))))

(ert-deftest hutch-agent-test-text-without-stream-errors ()
  (should (eq 'no-submit (car (hat--run "just prose" nil)))))

(ert-deftest hutch-agent-test-nil-response-includes-error ()
  (should (equal '(llm-error "Curl failure: exit code 56")
                 (hat--run nil '(:status "Curl failure" :error "exit code 56"))))
  (should (equal '(llm-error "HTTP/2 400: bad model")
                 (hat--run nil '(:status "HTTP/2 400"
                                 :error (:type "invalid" :message "bad model"))))))

;;; hutch-agent-test.el ends here
