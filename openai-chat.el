;;; openai-chat.el --- Create chat with OpenAI API  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Shen, Jen-Chieh

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Create a chat completion with OpenAI API.
;;
;; See https://platform.openai.com/docs/api-reference/chat
;;

;;; Code:

(require 'openai)
(require 'ewoc)

(defcustom openai-chat-model "gpt-3.5-turbo"
  "ID of the model to use.

You can use the List models API to see all of your available models."
  :type 'string
  :group 'openai)

(defcustom openai-chat-max-tokens 4096
  "The maximum number of tokens to generate in the chat.

The token count of your prompt plus max_tokens cannot exceed the model's context
length.  Most models have a context length of 2048 tokens (except for the newest
models, which support 4096)."
  :type 'integer
  :group 'openai)

(defcustom openai-chat-temperature 1.0
  "What sampling temperature to use.

Higher values means the model will take more risks.  Try 0.9 for more creative
applications, and 0 (argmax sampling) for ones with a well-defined answer."
  :type 'number
  :group 'openai)

(defcustom openai-chat-top-p 1.0
  "An alternative to sampling with temperature, called nucleus sampling, where
the model considers the results of the tokens with top_p probability mass.
So 0.1 means only the tokens comprising the top 10% probability mass are
considered.

We generally recommend altering this or `temperature' but not both."
  :type 'number
  :group 'openai)

(defcustom openai-chat-n 1
  "How many chats to generate for each prompt."
  :type 'integer
  :group 'openai)

(defcustom openai-chat-stream nil
  "Whether to stream back partial progress.

If set, tokens will be sent as data-only server-sent events as they become
available, with the stream terminated by a data: [DONE] message."
  :type 'boolean
  :group 'openai)

(defcustom openai-chat-stop nil
  "Up to 4 sequences where the API will stop generating further tokens.
The returned text will not contain the stop sequence."
  :type 'string
  :group 'openai)

(defcustom openai-chat-presence-penalty 0
  "Number between -2.0 and 2.0. Positive values penalize new tokens based on
whether they appear in the text so far, increasing the model's likelihood to
talk about new topics."
  :type 'number
  :group 'openai)

(defcustom openai-chat-frequency-penalty 0
  "Number between -2.0 and 2.0.

Positive values penalize new tokens based on their existing frequency in the
text so far, decreasing the model's likelihood to repeat the same line verbatim."
  :type 'number
  :group 'openai)

(defcustom openai-chat-logit-bias nil
  "Modify the likelihood of specified tokens appearing in the chat."
  :type 'list
  :group 'openai)

;;
;;; API

;;;###autoload
(defun openai-chat (query callback)
  "Query OpenAI with QUERY.

Argument CALLBACK is a function received one argument which is the JSON data."
  (openai-request "https://api.openai.com/v1/chat/completions"
    :type "POST"
    :headers `(("Content-Type"  . "application/json")
               ("Authorization" . ,(concat "Bearer " openai-key)))
    :data (json-encode
           `(("model"             . ,openai-chat-model)
             ("messages"          . ,query)
             ("temperature"       . ,openai-chat-temperature)
             ;;("top_p"             . ,openai-chat-top-p)
             ;;("n"                 . ,openai-chat-n)
             ;;("stream"            . ,(if openai-chat-stream "true" "false"))
             ;;("stop"              . ,openai-chat-stop)
             ("max_tokens"        . 512 ; ,openai-chat-max-tokens
              )
             ;;("presence_penalty"  . ,openai-chat-presence-penalty)
             ;;("frequency_penalty" . ,openai-chat-frequency-penalty)
             ;;("logit_bias"        . ,(if (listp openai-chat-logit-bias)
             ;;("user"              . ,openai-user)
             ))
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (funcall callback data)))))

;;
;;; Application
(defvar openai-result-temp nil "placeholder")

(defun openai-callback-temp (data)
  (setq openai-result-temp data))

(openai-chat
 openai-chat-sample-conversation
 'openai-callback-temp)

;; ========[  Herein lies some sample data for memory  ]========


(defvar openai-chat-sample-conversation
  [((role . "system")
    (content . "You are a helpful, pattern-following assistant that translates corporate jargon into plain English."))
   ((role . "system")
    (name . "example_user")
    (content . "New synergies will help drive top-line growth."))
   ((role . "system")
    (name . "example_assistant")
    (content . "Things working well together will increase revenue."))
   ((role . "system")
    (name . "example_user")
    (content . "Let's circle back when we have more bandwidth to touch base on opportunities for increased leverage."))
   ((role . "system")
    (name . "example_assistant")
    (content . "Let's talk later when we're less busy about how to do better."))
   ((role . "user")
    (content . "This late pivot means we don't have time to boil the ocean for the client deliverable."))]
  "A sample conversation for the chat endpoint")


;; ;;;###autoload
;; (defun openai-chat-buffer-insert ()
;;   "Send the entire buffer to OpenAI and insert the result to the end of buffer."
;;   (interactive)
;;   (openai-chat-select-insert (point-min) (point-max)))

(provide 'openai-chat)
;;; openai-chat.el ends here
