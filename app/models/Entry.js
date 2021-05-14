const mongoose = require('mongoose')

const EntrySchema = new mongoose.Schema({
    date: {
        type: Date,
        required: true
    },
    notes: {
        type: String,
        required: true
    },
    visibility: {
        type: String,
        default: 'private',
        enum: ['public', 'private']
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
})

module.exports = mongoose.model('Entry', EntrySchema)
