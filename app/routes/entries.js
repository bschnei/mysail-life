const express = require('express')
const router = express.Router()
const { ensureAuth } = require('../middleware/auth')

const Entry = require('../models/Entry')

// @desc    Show add page
// @route   GET /entries/add
router.get('/add', ensureAuth, (req, res) => {
    res.render('entries/add')
})

// @desc    Process add form
// @route   POST /entries
router.post('/', ensureAuth, async (req, res) => {
    try {
        req.body.user = req.user.id
        await Entry.create(req.body)
        res.redirect('/dashboard')
    } catch (err) {
        console.error(err)
        res.render('error/500')
    }
})

// @desc    Show all entries
// @route   GET /entries
router.get('/', ensureAuth, async (req, res) => {
    try {
        const entries = await Entry.find({ status: 'public' })
            .populate('user')
            .sort({ createdAt: 'desc' })
            .lean()
        
        res.render('entries/index', { entries })
    } catch (err) {
        console.error(err)
        res.render('error/500')
    }
})

// @desc    Show single entry
// @route   GET /entries/:id
router.get('/:id', ensureAuth, async (req, res) => {
    try {
        let entry = await Entry.findById(req.params.id)
            .populate('user')
            .lean()
        
        if (!entry) {
            return res.render('error/404')
        }

        if (entry.user._id != req.user.id && entry.status == 'private') {
            res.render('error/404')
          } else {
            res.render('entries/show', { entry })
        }

        res.render('entries/show', { entry })
    } catch (err) {
        console.error(err)
        res.render('error/404')
    }
})

// @desc    Show edit page
// @route   GET /entries/edit/:id
router.get('/edit/:id', ensureAuth, async (req, res) => {
    try {
        const entry = await Entry.findOne({
            _id: req.params.id
        }).lean()

        if (!entry){
            return res.render('error/404')
        }

        if (entry.user != req.user.id) {
            res.redirect('/entries')
        } else {
            res.render('entries/edit', { entry })
        }
    } catch (err) {
        console.error(err)
        res.render('error/500')
    }
})

// @desc    Update entry
// @route   PUT /entries/:id
router.put('/:id', ensureAuth, async (req, res) => {
    try {

        let entry = await Entry.findById(req.params.id).lean()

        if (!entry) {
            return res.render('error/404')
        }

        if (entry.user != req.user.id) {
            res.redirect('/entries')
        } else {
            entry = await Entry.findOneAndUpdate({ _id: req.params.id }, req.body, { new: true, runValidators: true })
            res.redirect('/dashboard')
        }
    } catch (err) {
        console.error(err)
        res.render('error/500')
    }
})

// @desc    Delete entry
// @route   DELETE /entries/:id
router.delete('/:id', ensureAuth, async (req, res) => {
    try {
        let entry = await Entry.remove({ _id: req.params.id })

        if (!entry) {
            return res.render('error/404')
        }
        
        if (entry.user != req.user.id) {
            res.redirect('/entries')
        } else {
            await Entry.remove({ _id: req.params.id })
            res.redirect('/dashboard')
        }

    } catch (err) {
        console.error(err)
        res.render('error/500')
    }
})


// @desc    User entries
// @route   GET /entries/user/:userId
router.get('/user/:userId', ensureAuth, async (req, res) => {
    try {
        const entries = await Entry.find({ user: req.params.userId, status: 'public' })
            .populate('user')
            .lean()
        
        res.render('entries/index', { entries })
    } catch (err) {
        console.error(err)
        res.render('error/500')
    }
})

module.exports = router
