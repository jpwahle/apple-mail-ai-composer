import Foundation

enum SystemPrompt {
    static func compose(context: ComposerContext, userThoughts: String, customInstructions: String = "") -> (system: String, user: String) {
        let system = """
        You are an email writing assistant. Compose the body of an email based on the \
        context from the user's open compose window and the user's thoughts about what \
        to say.

        ## Rules
        - Output ONLY the body text. No explanations, no markdown, no subject line.
        - Match the greeting style of the thread when one exists (e.g. "Hi Sarah," or \
        "Dear Mr. Smith,"). For a new email with no thread, pick a greeting appropriate \
        to the recipient and register.
        - If the thread or draft is in German, write in German and end with "Beste Grüße".
        - If the thread or draft is in English, write in English and end with "Best wishes".
        - Do not use any other sign-off.
        - Match the formality level of the incoming emails. Mostly informal, but sometimes formal.

        ## Writing Style
        - Keep paragraphs short (2-3 sentences max). Short paragraphs put air around what \
        you write and make it look inviting.
        - Use simple, clear language. Use easy words instead of complicated ones. Remove \
        unnecessary words and sentences.
        - Use strong, active verbs. Never use passive voice.
        - Do not use excessive empty adjectives and modifiers like "crucial", "important", \
        "beyond".
        - Do not use qualifiers like "a bit," "quite," "pretty much," "in a sense," or \
        "a little." Be direct and confident.
        - Vary sentence length like music: short, long, and medium sentences.
        - Make sentences as short as possible without losing context.
        - Never use semicolons.
        - Use the colon only to enumerate things.
        - Use "that" instead of "which".
        - Do not use an en-dash unless absolutely necessary.
        - Use adverbs and adjectives sparingly — only when they add an unambiguous property \
        that is otherwise unclear.
        - Be credible. Do not inflate statements.
        - Make the first sentence stand out so the reader keeps reading.
        - Convey one clear idea per paragraph.
        - Do not start with filler like "I hope this email finds you well."
        """

        var userParts: [String] = []

        userParts.append("## Compose window")
        userParts.append("Subject: \(context.subject.isEmpty ? "(none)" : context.subject)")
        if context.hasRecipients {
            userParts.append("To: \(context.recipients.joined(separator: ", "))")
        } else {
            userParts.append("To: (no recipients yet)")
        }

        if !context.currentDraft.isEmpty {
            userParts.append("")
            userParts.append("## Existing draft in compose window")
            userParts.append(context.currentDraft)
        }

        if let thread = context.thread, !thread.messages.isEmpty {
            userParts.append("")
            userParts.append("## Previous email thread")
            userParts.append(thread.formatted())
        } else {
            userParts.append("")
            userParts.append("## Previous email thread")
            userParts.append("(none — this is a new email)")
        }

        userParts.append("")
        userParts.append("## My thoughts for what to write")
        userParts.append(userThoughts)

        var finalSystem = system
        let trimmedInstructions = customInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedInstructions.isEmpty {
            finalSystem += "\n\n## Additional instructions from the user\n" + trimmedInstructions
        }

        return (finalSystem, userParts.joined(separator: "\n"))
    }

    /// Builds prompts for a TL;DR-style summary of the current email thread.
    /// The summary is meant to stand on its own — never inserted back into Mail.
    static func summarize(context: ComposerContext, customInstructions: String = "") -> (system: String, user: String) {
        let system = """
        You are an email summarizer. Produce a tight TL;DR of the email thread for \
        someone who has not read it.

        ## Rules
        - Output ONLY the summary. No preamble, no explanations, no markdown headers.
        - Start with a single sentence that captures the gist.
        - Then list key points as plain-text bullets prefixed with "• ".
        - 3 to 7 bullets. Use fewer if the thread genuinely has fewer distinct points.
        - Each bullet: one clear, complete idea, max 20 words.
        - Capture decisions, action items, deadlines, open questions, and anything \
        the reader needs to do or know.
        - Name people when they matter. Identify who is asking what of whom.
        - Prefer concrete details (dates, numbers, names) over vague summaries.
        - If the thread is in German, write the summary in German. If English, in \
        English. Match the language of the most recent message.
        - No filler. Skip phrases like "this thread discusses" or "in summary". Go \
        straight to the substance.
        - Do not invent facts. If something is unclear in the thread, say so plainly.
        """

        var userParts: [String] = []

        userParts.append("## Thread to summarize")
        userParts.append("Subject: \(context.subject.isEmpty ? "(none)" : context.subject)")
        if context.hasRecipients {
            userParts.append("Recipients: \(context.recipients.joined(separator: ", "))")
        }

        if let thread = context.thread, !thread.messages.isEmpty {
            userParts.append("")
            userParts.append("## Messages")
            userParts.append(thread.formatted())
        }

        if !context.currentDraft.isEmpty {
            userParts.append("")
            userParts.append("## Existing draft in compose window (for context only)")
            userParts.append(context.currentDraft)
        }

        var finalSystem = system
        let trimmedInstructions = customInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedInstructions.isEmpty {
            finalSystem += "\n\n## Additional instructions from the user\n" + trimmedInstructions
        }

        return (finalSystem, userParts.joined(separator: "\n"))
    }
}
